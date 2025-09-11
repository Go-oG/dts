import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/point.dart';

import 'overlay_edge.dart';
import 'overlay_graph.dart';
import 'overlay_label.dart';
import 'overlay_ng.dart';

class IntersectionPointBuilder {
  GeometryFactory geometryFactory;

  final OverlayGraph _graph;

  final List<Point> _points = [];

  bool _isAllowCollapseLines = !OverlayNG.strictModeDefault;

  IntersectionPointBuilder(this._graph, this.geometryFactory);

  void setStrictMode(bool isStrictMode) {
    _isAllowCollapseLines = !isStrictMode;
  }

  List<Point> getPoints() {
    addResultPoints();
    return _points;
  }

  void addResultPoints() {
    for (OverlayEdge nodeEdge in _graph.getNodeEdges()) {
      if (isResultPoint(nodeEdge)) {
        Point pt =
            geometryFactory.createPoint2(nodeEdge.getCoordinate().copy());
        _points.add(pt);
      }
    }
  }

  bool isResultPoint(OverlayEdge nodeEdge) {
    bool isEdgeOfA = false;
    bool isEdgeOfB = false;
    OverlayEdge? edge = nodeEdge;
    do {
      if (edge!.isInResult()) {
        return false;
      }
      OverlayLabel label = edge.getLabel();
      isEdgeOfA |= isEdgeOf(label, 0);
      isEdgeOfB |= isEdgeOf(label, 1);
      edge = edge.oNext() as OverlayEdge?;
    } while (edge != nodeEdge);
    bool isNodeInBoth = isEdgeOfA && isEdgeOfB;
    return isNodeInBoth;
  }

  bool isEdgeOf(OverlayLabel label, int i) {
    if ((!_isAllowCollapseLines) && label.isBoundaryCollapse()) return false;

    return label.isBoundary(i) || label.isLine2(i);
  }
}
