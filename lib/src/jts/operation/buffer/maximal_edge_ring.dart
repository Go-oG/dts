import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/edge_ring.dart';
import 'package:dts/src/jts/geomgraph/node.dart';

import 'minimal_edge_ring.dart';

class MaximalEdgeRing extends EdgeRing {
  MaximalEdgeRing(super.start, super.geometryFactory);

  @override
  DirectedEdge? getNext(DirectedEdge de) {
    return de.getNext();
  }

  @override
  void setEdgeRing(DirectedEdge de, EdgeRing er) {
    de.setEdgeRing(er);
  }

  void linkDirectedEdgesForMinimalEdgeRings() {
    DirectedEdge? de = startDe!;
    do {
      Node node = de!.getNode();
      (node.getEdges() as DirectedEdgeStar).linkMinimalDirectedEdges(this);
      de = de.getNext();
    } while (de != startDe);
  }

  List<MinimalEdgeRing> buildMinimalRings() {
    List<MinimalEdgeRing> minEdgeRings = [];
    DirectedEdge? de = startDe;
    do {
      if (de!.getMinEdgeRing() == null) {
        final minEr = MinimalEdgeRing(de, geometryFactory);
        minEdgeRings.add(minEr);
      }
      de = de.getNext();
    } while (de != startDe);
    return minEdgeRings;
  }
}
