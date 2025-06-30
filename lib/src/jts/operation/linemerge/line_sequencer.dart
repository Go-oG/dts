import 'dart:collection';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_component_filter.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';
import 'package:dts/src/jts/planargraph/algorithm/connected_subgraph_finder.dart';
import 'package:dts/src/jts/planargraph/directed_edge.dart';
import 'package:dts/src/jts/planargraph/graph_component.dart';
import 'package:dts/src/jts/planargraph/node.dart';
import 'package:dts/src/jts/planargraph/subgraph.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'line_merge_edge.dart';
import 'line_merge_graph.dart';

class LineSequencer {
  static Geometry sequence(Geometry geom) {
    LineSequencer sequencer = LineSequencer();
    sequencer.add(geom);
    return sequencer.getSequencedLineStrings();
  }

  static bool isSequenced(Geometry mls) {
    if (mls is! MultiLineString) {
      return true;
    }
    Set prevSubgraphNodes = SplayTreeSet();
    Coordinate? lastNode;
    List currNodes = [];
    for (int i = 0; i < mls.getNumGeometries(); i++) {
      LineString line = mls.getGeometryN(i);
      Coordinate startNode = line.getCoordinateN(0);
      Coordinate endNode = line.getCoordinateN(line.getNumPoints() - 1);
      if (prevSubgraphNodes.contains(startNode)) {
        return false;
      }

      if (prevSubgraphNodes.contains(endNode)) {
        return false;
      }

      if (lastNode != null) {
        if (startNode != lastNode) {
          prevSubgraphNodes.addAll(currNodes);
          currNodes.clear();
        }
      }
      currNodes.add(startNode);
      currNodes.add(endNode);
      lastNode = endNode;
    }
    return true;
  }

  final graph = LineMergeGraph();

  GeomFactory? _factory = GeomFactory();

  int _lineCount = 0;

  bool _isRun = false;

  Geometry? _sequencedGeometry;

  bool _isSequenceable = false;

  void addAll(List<Geometry> geometries) {
    for (var g in geometries) {
      add(g);
    }
  }

  void add(Geometry geometry) {
    geometry.apply4(
      GeomComponentFilter2((g) {
        if (g is LineString) {
          addLine(g);
        }
      }),
    );
  }

  void addLine(LineString lineString) {
    _factory ??= lineString.factory;
    graph.addEdge(lineString);
    _lineCount++;
  }

  bool isSequenceable() {
    computeSequence();
    return _isSequenceable;
  }

  Geometry getSequencedLineStrings() {
    computeSequence();
    return _sequencedGeometry!;
  }

  void computeSequence() {
    if (_isRun) {
      return;
    }
    _isRun = true;
    List<List<DirectedEdgePG>>? sequences = findSequences();
    if (sequences == null) {
      return;
    }

    _sequencedGeometry = buildSequencedGeometry(sequences);
    _isSequenceable = true;
    int finalLineCount = _sequencedGeometry!.getNumGeometries();
    Assert.isTrue2(_lineCount == finalLineCount, "Lines were missing from result");
    Assert.isTrue2(
      (_sequencedGeometry is LineString) || (_sequencedGeometry is MultiLineString),
      "Result is not lineal",
    );
  }

  List<List<DirectedEdgePG>>? findSequences() {
    List<List<DirectedEdgePG>> sequences = [];
    ConnectedSubgraphFinder csFinder = ConnectedSubgraphFinder(graph);
    final subgraphs = csFinder.getConnectedSubGraphs();
    for (var subgraph in subgraphs) {
      if (hasSequence(subgraph)) {
        List<DirectedEdgePG> seq = findSequence(subgraph);
        sequences.add(seq);
      } else {
        return null;
      }
    }
    return sequences;
  }

  bool hasSequence(Subgraph graph) {
    int oddDegreeCount = 0;
    for (var node in graph.nodeIterator()) {
      if ((node.getDegree() % 2) == 1) {
        oddDegreeCount++;
      }
    }
    return oddDegreeCount <= 2;
  }

  List<DirectedEdgePG> findSequence(Subgraph graph) {
    GraphComponentPG.setVisited2(graph.edgeIterator(), false);
    PGNode startNode = findLowestDegreeNode(graph)!;
    DirectedEdgePG startDE = startNode.getOutEdges().iterator().first;
    DirectedEdgePG startDESym = startDE.getSym()!;
    List<DirectedEdgePG> seq = [];
    ListIterator<DirectedEdgePG> lit = seq.listIterator();
    addReverseSubPath(startDESym, lit, false);
    while (lit.hasPrevious()) {
      DirectedEdgePG prev = lit.previous();
      DirectedEdgePG? unvisitedOutDE = findUnvisitedBestOrientedDE(prev.getFromNode());
      if (unvisitedOutDE != null) {
        addReverseSubPath(unvisitedOutDE.getSym()!, lit, true);
      }
    }
    return orient(seq);
  }

  static DirectedEdgePG? findUnvisitedBestOrientedDE(PGNode node) {
    DirectedEdgePG? wellOrientedDE;
    DirectedEdgePG? unvisitedDE;
    for (var de in node.getOutEdges().iterator()) {
      if (!de.getEdge()!.isVisited) {
        unvisitedDE = de;
        if (de.getEdgeDirection()) {
          wellOrientedDE = de;
        }
      }
    }
    if (wellOrientedDE != null) {
      return wellOrientedDE;
    }
    return unvisitedDE;
  }

  void addReverseSubPath(DirectedEdgePG de, ListIterator<DirectedEdgePG> lit, bool expectedClosed) {
    PGNode endNode = de.getToNode();
    PGNode? fromNode;
    while (true) {
      lit.add(de.getSym()!);
      de.getEdge()!.isVisited = true;
      fromNode = de.getFromNode();
      DirectedEdgePG? unvisitedOutDE = findUnvisitedBestOrientedDE(fromNode);
      if (unvisitedOutDE == null) {
        break;
      }
      de = unvisitedOutDE.getSym()!;
    }
    if (expectedClosed) {
      Assert.isTrue2(fromNode == endNode, "path not contiguous");
    }
  }

  static PGNode? findLowestDegreeNode(Subgraph graph) {
    int minDegree = Integer.maxValue;
    PGNode? minDegreeNode;
    for (var node in graph.nodeIterator()) {
      if ((minDegreeNode == null) || (node.getDegree() < minDegree)) {
        minDegree = node.getDegree();
        minDegreeNode = node;
      }
    }
    return minDegreeNode;
  }

  List<DirectedEdgePG> orient(List<DirectedEdgePG> seq) {
    DirectedEdgePG startEdge = seq.first;
    DirectedEdgePG endEdge = seq.last;
    PGNode startNode = startEdge.getFromNode();
    PGNode endNode = endEdge.getToNode();
    bool flipSeq = false;
    bool hasDegree1Node = (startNode.getDegree() == 1) || (endNode.getDegree() == 1);
    if (hasDegree1Node) {
      bool hasObviousStartNode = false;
      if ((endEdge.getToNode().getDegree() == 1) && (!endEdge.getEdgeDirection())) {
        hasObviousStartNode = true;
        flipSeq = true;
      }
      if ((startEdge.getFromNode().getDegree() == 1) && startEdge.getEdgeDirection()) {
        hasObviousStartNode = true;
        flipSeq = false;
      }
      if (!hasObviousStartNode) {
        if (startEdge.getFromNode().getDegree() == 1) {
          flipSeq = true;
        }
      }
    }
    if (flipSeq) {
      return _reverse(seq);
    }

    return seq;
  }

  List<DirectedEdgePG> _reverse(List<DirectedEdgePG> seq) {
    List<DirectedEdgePG> newSeq = [];
    for (Iterator i = seq.iterator; i.moveNext();) {
      DirectedEdgePG de = i.current;
      newSeq.insert(0, de.getSym()!);
    }
    return newSeq;
  }

  Geometry buildSequencedGeometry(List<List<DirectedEdgePG>> sequences) {
    List<LineString> lines = [];
    for (var i1 = sequences.iterator; i1.moveNext();) {
      final seq = i1.current;
      for (var i2 = seq.iterator; i2.moveNext();) {
        DirectedEdgePG de = i2.current;
        LineMergeEdge e = de.getEdge() as LineMergeEdge;
        LineString line = e.getLine();
        LineString lineToAdd = line;
        if ((!de.getEdgeDirection()) && (!line.isClosed())) {
          lineToAdd = _reverse2(line);
        }

        lines.add(lineToAdd);
      }
    }
    if (lines.size == 0) {
      return _factory!.createMultiLineString(Array<LineString>(0));
    }

    return _factory!.buildGeometry(lines);
  }

  static LineString _reverse2(LineString line) {
    Array<Coordinate> pts = line.getCoordinates();
    Array<Coordinate> revPts = Array(pts.length);
    int len = pts.length;
    for (int i = 0; i < len; i++) {
      revPts[(len - 1) - i] = Coordinate.of(pts[i]);
    }
    return line.factory.createLineString2(revPts);
  }
}
