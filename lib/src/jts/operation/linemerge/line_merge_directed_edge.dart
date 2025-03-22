
import 'package:dts/src/jts/planargraph/directed_edge.dart';
import 'package:dts/src/jts/util/assert.dart';

class LineMergeDirectedEdge extends DirectedEdgePG {
  LineMergeDirectedEdge(super.from, super.to, super.directionPt, super.edgeDirection);

  LineMergeDirectedEdge? getNext() {
    if (getToNode().getDegree() != 2) {
      return null;
    }
    if (getToNode().getOutEdges().getEdges().first == getSym()) {
      return getToNode().getOutEdges().getEdges()[1] as LineMergeDirectedEdge;
    }
    Assert.isTrue(getToNode().getOutEdges().getEdges()[1] == getSym());
    return getToNode().getOutEdges().getEdges().first as LineMergeDirectedEdge;
  }
}
