import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/edge_ring.dart';


class MinimalEdgeRing extends EdgeRing {
  MinimalEdgeRing(super.start, super.geometryFactory);

  @override
  DirectedEdge getNext(DirectedEdge de) {
    return de.getNextMin();
    }

  @override
  void setEdgeRing(DirectedEdge de, EdgeRing er) {
    de.setMinEdgeRing(er);
    }
}
