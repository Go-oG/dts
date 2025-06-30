import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_component_filter.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/planargraph/graph_component.dart';
import 'package:dts/src/jts/planargraph/node.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'edge_string.dart';
import 'line_merge_directed_edge.dart';
import 'line_merge_graph.dart';

class LineMerger {
  final _graph = LineMergeGraph();

  List<LineString>? _mergedLineStrings;

  GeomFactory? factory;

  void add(Geometry geometry) {
    geometry.apply4(
      GeomComponentFilter2((com) {
        if (com is LineString) {
          add3(com);
        }
      }),
    );
  }

  void add2(List<Geometry> geometries) {
    _mergedLineStrings = null;
    for (var ge in geometries) {
      add(ge);
    }
  }

  void add3(LineString lineString) {
    factory ??= lineString.factory;
    _graph.addEdge(lineString);
  }

  late List<EdgeString> _edgeStrings;

  void merge() {
    if (_mergedLineStrings != null) {
      return;
    }
    GraphComponentPG.setMarked2(_graph.nodeIterator(), false);
    GraphComponentPG.setMarked2(_graph.edgeIterator(), false);
    _edgeStrings = [];
    buildEdgeStringsForObviousStartNodes();
    buildEdgeStringsForIsolatedLoops();
    _mergedLineStrings = [];
    for (Iterator i = _edgeStrings.iterator; i.moveNext();) {
      EdgeString edgeString = i.current;
      _mergedLineStrings!.add(edgeString.toLineString());
    }
  }

  void buildEdgeStringsForObviousStartNodes() {
    buildEdgeStringsForNonDegree2Nodes();
  }

  void buildEdgeStringsForIsolatedLoops() {
    buildEdgeStringsForUnprocessedNodes();
  }

  void buildEdgeStringsForUnprocessedNodes() {
    for (var i = _graph.getNodes().iterator; i.moveNext();) {
      PGNode node = i.current;
      if (!node.isMarked) {
        Assert.isTrue(node.getDegree() == 2);
        buildEdgeStringsStartingAt(node);
        node.isMarked = true;
      }
    }
  }

  void buildEdgeStringsForNonDegree2Nodes() {
    for (var i = _graph.getNodes().iterator; i.moveNext();) {
      PGNode node = i.current;
      if (node.getDegree() != 2) {
        buildEdgeStringsStartingAt(node);
        node.isMarked = (true);
      }
    }
  }

  void buildEdgeStringsStartingAt(PGNode node) {
    for (var de in node.getOutEdges().iterator()) {
      if (de.getEdge()!.isMarked) {
        continue;
      }
      _edgeStrings.add(buildEdgeStringStartingWith(de as LineMergeDirectedEdge));
    }
  }

  EdgeString buildEdgeStringStartingWith(LineMergeDirectedEdge start) {
    EdgeString edgeString = EdgeString(factory!);
    LineMergeDirectedEdge? current = start;
    do {
      edgeString.add(current!);
      current.getEdge()!.isMarked = (true);
      current = current.getNext();
    } while ((current != null) && (current != start));
    return edgeString;
  }

  List<LineString> getMergedLineStrings() {
    merge();
    return _mergedLineStrings!;
  }
}
