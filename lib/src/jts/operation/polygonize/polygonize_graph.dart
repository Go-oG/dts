import 'package:d_util/d_util.dart' show Stack;
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/operation/polygonize/polygonize_directed_edge.dart';
import 'package:dts/src/jts/planargraph/directed_edge.dart';
import 'package:dts/src/jts/planargraph/directed_edge_star.dart';
import 'package:dts/src/jts/planargraph/edge.dart';
import 'package:dts/src/jts/planargraph/node.dart';
import 'package:dts/src/jts/planargraph/planar_graph.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'edge_ring.dart';
import 'polygonize_edge.dart';

class PolygonizeGraph extends PlanarGraph {
  static int getDegreeNonDeleted(PGNode node) {
    List<DirectedEdgePG> edges = node.getOutEdges().getEdges();
    int degree = 0;
    for (var i = edges.iterator; i.moveNext();) {
      PolygonizeDirectedEdge de = i.current as PolygonizeDirectedEdge;
      if (!de.isMarked) {
        degree++;
      }
    }
    return degree;
  }

  static int getDegree(PGNode node, int label) {
    List<DirectedEdgePG> edges = node.getOutEdges().getEdges();
    int degree = 0;
    for (var i = edges.iterator; i.moveNext();) {
      PolygonizeDirectedEdge de = i.current as PolygonizeDirectedEdge;
      if (de.label == label) {
        degree++;
      }
    }
    return degree;
  }

  static void deleteAllEdges(PGNode node) {
    List<DirectedEdgePG> edges = node.getOutEdges().getEdges();
    for (var i = edges.iterator; i.moveNext();) {
      PolygonizeDirectedEdge de = i.current as PolygonizeDirectedEdge;
      de.isMarked = (true);
      PolygonizeDirectedEdge? sym = (de.getSym() as PolygonizeDirectedEdge?);
      if (sym != null) {
        sym.isMarked = true;
      }
    }
  }

  GeometryFactory factory;

  PolygonizeGraph(this.factory);

  void addEdge(LineString line) {
    if (line.isEmpty()) {
      return;
    }
    final linePts =
        CoordinateArrays.removeRepeatedPoints(line.getCoordinates());
    if (linePts.length < 2) {
      return;
    }
    Coordinate startPt = linePts[0];
    Coordinate endPt = linePts[linePts.length - 1];
    PGNode nStart = getNode(startPt);
    PGNode nEnd = getNode(endPt);
    DirectedEdgePG de0 = PolygonizeDirectedEdge(nStart, nEnd, linePts[1], true);
    DirectedEdgePG de1 = PolygonizeDirectedEdge(
        nEnd, nStart, linePts[linePts.length - 2], false);
    PGEdge edge = PolygonizeEdge(line);
    edge.setDirectedEdges(de0, de1);
    add(edge);
  }

  PGNode getNode(Coordinate pt) {
    PGNode? node = findNode(pt);
    if (node == null) {
      node = PGNode(pt);
      add2(node);
    }
    return node;
  }

  void _computeNextCWEdges() {
    for (var node in nodeIterator()) {
      _computeNextCWEdgesS(node);
    }
  }

  void convertMaximalToMinimalEdgeRings(
      List<PolygonizeDirectedEdge> ringEdges) {
    for (PolygonizeDirectedEdge de in ringEdges) {
      int label = de.label;
      List<PGNode>? intNodes = findIntersectionNodes(de, label);
      if (intNodes == null) {
        continue;
      }

      for (PGNode node in intNodes) {
        computeNextCCWEdges(node, label);
      }
    }
  }

  static List<PGNode>? findIntersectionNodes(
      PolygonizeDirectedEdge startDE, int label) {
    PolygonizeDirectedEdge? de = startDE;
    List<PGNode>? intNodes;
    do {
      PGNode node = de!.getFromNode();
      if (getDegree(node, label) > 1) {
        intNodes ??= [];
        intNodes.add(node);
      }
      de = de.next;
      Assert.isTrue(de != null, "found null DE in ring");
      Assert.isTrue(
          de == startDE || !de!.isInRing(), "found DE already in ring");
    } while (de != startDE);
    return intNodes;
  }

  List<EdgeRingO> getEdgeRings() {
    _computeNextCWEdges();
    label(dirEdges.cast(), -1);
    List<PolygonizeDirectedEdge> maximalRings = findLabeledEdgeRings(dirEdges);
    convertMaximalToMinimalEdgeRings(maximalRings);
    List<EdgeRingO> edgeRingList = [];
    for (var i = dirEdges.iterator; i.moveNext();) {
      PolygonizeDirectedEdge de = i.current as PolygonizeDirectedEdge;
      if (de.isMarked) continue;

      if (de.isInRing()) {
        continue;
      }

      EdgeRingO er = findEdgeRing(de);
      edgeRingList.add(er);
    }
    return edgeRingList;
  }

  static List<PolygonizeDirectedEdge> findLabeledEdgeRings(
      Iterable<DirectedEdgePG> dirEdges) {
    List<PolygonizeDirectedEdge> edgeRingStarts = [];
    int currLabel = 1;
    for (var i = dirEdges.iterator; i.moveNext();) {
      PolygonizeDirectedEdge de = i.current as PolygonizeDirectedEdge;
      if (de.isMarked) continue;

      if (de.label >= 0) continue;

      edgeRingStarts.add(de);
      List<PolygonizeDirectedEdge> edges = EdgeRingO.findDirEdgesInRing(de);
      label(edges, currLabel);
      currLabel++;
    }
    return edgeRingStarts;
  }

  List<LineString> deleteCutEdges() {
    _computeNextCWEdges();
    findLabeledEdgeRings(dirEdges);
    List<LineString> cutLines = [];
    for (var i = dirEdges.iterator; i.moveNext();) {
      PolygonizeDirectedEdge de = i.current as PolygonizeDirectedEdge;
      if (de.isMarked) continue;

      PolygonizeDirectedEdge sym = de.getSym() as PolygonizeDirectedEdge;
      if (de.label == sym.label) {
        de.isMarked = (true);
        sym.isMarked = (true);
        PolygonizeEdge e = (de.getEdge() as PolygonizeEdge);
        cutLines.add(e.getLine());
      }
    }
    return cutLines;
  }

  static void label(Iterable<PolygonizeDirectedEdge> dirEdges, int label) {
    for (var i = dirEdges.iterator; i.moveNext();) {
      PolygonizeDirectedEdge de = i.current;
      de.label = (label);
    }
  }

  static void _computeNextCWEdgesS(PGNode node) {
    DirectedEdgeStarPG deStar = node.getOutEdges();
    PolygonizeDirectedEdge? startDE;
    PolygonizeDirectedEdge? prevDE;
    for (var i = deStar.getEdges().iterator; i.moveNext();) {
      PolygonizeDirectedEdge outDE = i.current as PolygonizeDirectedEdge;
      if (outDE.isMarked) continue;

      startDE ??= outDE;

      if (prevDE != null) {
        PolygonizeDirectedEdge sym = prevDE.getSym() as PolygonizeDirectedEdge;
        sym.next = (outDE);
      }
      prevDE = outDE;
    }
    if (prevDE != null) {
      PolygonizeDirectedEdge sym = prevDE.getSym() as PolygonizeDirectedEdge;
      sym.next = (startDE);
    }
  }

  static void computeNextCCWEdges(PGNode node, int label) {
    DirectedEdgeStarPG deStar = node.getOutEdges();
    PolygonizeDirectedEdge? firstOutDE;
    PolygonizeDirectedEdge? prevInDE;
    final edges = deStar.getEdges();

    for (int i = edges.length - 1; i >= 0; i--) {
      PolygonizeDirectedEdge de = edges[i] as PolygonizeDirectedEdge;
      PolygonizeDirectedEdge sym = de.getSym() as PolygonizeDirectedEdge;
      PolygonizeDirectedEdge? outDE;
      if (de.label == label) {
        outDE = de;
      }

      PolygonizeDirectedEdge? inDE;
      if (sym.label == label) {
        inDE = sym;
      }

      if ((outDE == null) && (inDE == null)) {
        continue;
      }

      if (inDE != null) {
        prevInDE = inDE;
      }
      if (outDE != null) {
        if (prevInDE != null) {
          prevInDE.next = (outDE);
          prevInDE = null;
        }
        firstOutDE ??= outDE;
      }
    }
    if (prevInDE != null) {
      Assert.isTrue(firstOutDE != null);
      prevInDE.next = firstOutDE;
    }
  }

  EdgeRingO findEdgeRing(PolygonizeDirectedEdge startDE) {
    EdgeRingO er = EdgeRingO(factory);
    er.build(startDE);
    return er;
  }

  List<LineString> deleteDangles() {
    List<PGNode> nodesToRemove = findNodesOfDegree(1);
    List<LineString> dangleLines = [];
    Stack<PGNode> nodeStack = Stack<PGNode>();
    for (Iterator<PGNode> i = nodesToRemove.iterator; i.moveNext();) {
      nodeStack.push(i.current);
    }
    while (nodeStack.isNotEmpty) {
      PGNode node = nodeStack.pop();
      deleteAllEdges(node);
      final nodeOutEdges = node.getOutEdges().getEdges();
      for (var i = nodeOutEdges.iterator; i.moveNext();) {
        PolygonizeDirectedEdge de = i.current as PolygonizeDirectedEdge;
        de.isMarked = true;
        PolygonizeDirectedEdge? sym = de.getSym() as PolygonizeDirectedEdge?;
        if (sym != null) {
          sym.isMarked = true;
        }

        PolygonizeEdge e = de.getEdge() as PolygonizeEdge;
        dangleLines.add(e.getLine());
        PGNode toNode = de.getToNode();
        if (getDegreeNonDeleted(toNode) == 1) {
          nodeStack.push(toNode);
        }
      }
    }
    return dangleLines;
  }
}
