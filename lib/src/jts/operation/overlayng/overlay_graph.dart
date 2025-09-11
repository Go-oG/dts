import 'package:dts/src/jts/geom/coordinate.dart';

import 'overlay_edge.dart';
import 'overlay_label.dart';

class OverlayGraph {
  final List<OverlayEdge> _edges = [];

  final Map<Coordinate, OverlayEdge> _nodeMap = {};

  List<OverlayEdge> getEdges() {
    return _edges;
  }

  List<OverlayEdge> getNodeEdges() {
    return _nodeMap.values.toList();
  }

  OverlayEdge? getNodeEdge(Coordinate nodePt) {
    return _nodeMap[nodePt];
  }

  List<OverlayEdge> getResultAreaEdges() {
    List<OverlayEdge> resultEdges = [];
    for (OverlayEdge edge in getEdges()) {
      if (edge.isInResultArea()) {
        resultEdges.add(edge);
      }
    }
    return resultEdges;
  }

  OverlayEdge addEdge(List<Coordinate> pts, OverlayLabel label) {
    OverlayEdge e = OverlayEdge.createEdgePair(pts, label);
    insert(e);
    insert(e.symOE());
    return e;
  }

  void insert(OverlayEdge e) {
    _edges.add(e);
    OverlayEdge? nodeEdge = _nodeMap[e.orig()];
    if (nodeEdge != null) {
      nodeEdge.insert(e);
    } else {
      _nodeMap[e.orig()] = e;
    }
  }
}
