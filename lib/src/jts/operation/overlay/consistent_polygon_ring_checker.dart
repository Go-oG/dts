import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/label.dart';
import 'package:dts/src/jts/geomgraph/planar_graph.dart';

import 'overlay_op.dart';

class ConsistentPolygonRingChecker {
  PGPlanarGraph graph;

  ConsistentPolygonRingChecker(this.graph);

  void checkAll() {
    check(OverlayOpCode.intersection);
    check(OverlayOpCode.difference);
    check(OverlayOpCode.union);
    check(OverlayOpCode.symDifference);
  }

  void check(OverlayOpCode opCode) {
    for (var node in graph.getNodeIterator()) {
      testLinkResultDirectedEdges(node.getEdges() as DirectedEdgeStar, opCode);
    }
  }

  List<DirectedEdge> getPotentialResultAreaEdges(
      DirectedEdgeStar deStar, OverlayOpCode opCode) {
    List<DirectedEdge> resultAreaEdgeList = [];
    for (var it in deStar.iterator()) {
      DirectedEdge de = it as DirectedEdge;
      if (isPotentialResultAreaEdge(de, opCode) ||
          isPotentialResultAreaEdge(de.getSym(), opCode)) {
        resultAreaEdgeList.add(de);
      }
    }
    return resultAreaEdgeList;
  }

  bool isPotentialResultAreaEdge(DirectedEdge de, OverlayOpCode opCode) {
    Label label = de.label!;
    if ((label.isArea() && (!de.isInteriorAreaEdge())) &&
        OverlayOp.isResultOfOp2(label.getLocation2(0, Position.right),
            label.getLocation2(1, Position.right), opCode)) {
      return true;
    }
    return false;
  }

  static const int scaningForIncoming = 1;
  static const int linkingToOutgoing = 2;

  void testLinkResultDirectedEdges(
      DirectedEdgeStar deStar, OverlayOpCode opCode) {
    final ringEdges = getPotentialResultAreaEdges(deStar, opCode);
    DirectedEdge? firstOut;
    DirectedEdge? incoming;
    int state = scaningForIncoming;
    for (int i = 0; i < ringEdges.length; i++) {
      DirectedEdge nextOut = ringEdges[i];
      DirectedEdge nextIn = nextOut.getSym();
      if (!nextOut.getLabel()!.isArea()) {
        continue;
      }

      if ((firstOut == null) && isPotentialResultAreaEdge(nextOut, opCode)) {
        firstOut = nextOut;
      }

      switch (state) {
        case scaningForIncoming:
          if (!isPotentialResultAreaEdge(nextIn, opCode)) {
            continue;
          }
          incoming = nextIn;
          state = linkingToOutgoing;
          break;
        case linkingToOutgoing:
          if (!isPotentialResultAreaEdge(nextOut, opCode)) {
            continue;
          }

          state = scaningForIncoming;
          break;
      }
    }
    if (state == linkingToOutgoing) {
      if (firstOut == null) {
        throw TopologyException(
            "no outgoing dirEdge found", deStar.getCoordinate());
      }
    }
  }
}
