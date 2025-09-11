import 'package:dts/src/jts/planargraph/directed_edge.dart';

import 'edge_ring.dart';

class PolygonizeDirectedEdge extends DirectedEdgePG {
  EdgeRingO? _edgeRing;

  PolygonizeDirectedEdge? next;

  int label = -1;

  PolygonizeDirectedEdge(
      super.from, super.to, super.directionPt, super.edgeDirection);

  bool isInRing() {
    return _edgeRing != null;
  }

  void setRing(EdgeRingO? edgeRing) {
    _edgeRing = edgeRing;
  }

  EdgeRingO? getRing() {
    return _edgeRing;
  }
}
