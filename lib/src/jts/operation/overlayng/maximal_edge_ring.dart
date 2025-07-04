import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'overlay_edge.dart';
import 'overlay_edge_ring.dart';

class NgMaximalEdgeRing {
  static const int _kStateFindIncoming = 1;

  static const int _kStateLinkOutgoing = 2;

  static void linkResultAreaMaxRingAtNode(OverlayEdge nodeEdge) {
    Assert.isTrue(nodeEdge.isInResultArea(), "Attempt to link non-result edge");
    OverlayEdge? endOut = nodeEdge.oNextOE();
    OverlayEdge? currOut = endOut;
    int state = _kStateFindIncoming;
    OverlayEdge? currResultIn;
    do {
      if ((currResultIn != null) && currResultIn.isResultMaxLinked()) {
        return;
      }

      switch (state) {
        case _kStateFindIncoming:
          OverlayEdge currIn = currOut!.symOE();
          if (!currIn.isInResultArea()) {
            break;
          }

          currResultIn = currIn;
          state = _kStateLinkOutgoing;
          break;
        case _kStateLinkOutgoing:
          if (!currOut!.isInResultArea()) {
            break;
          }

          currResultIn!.setNextResultMax(currOut);
          state = _kStateFindIncoming;
          break;
      }
      currOut = currOut!.oNextOE();
    } while (currOut != endOut);
    if (state == _kStateLinkOutgoing) {
      throw TopologyException("no outgoing edge found", nodeEdge.getCoordinate());
    }
  }

  final OverlayEdge _startEdge;

  NgMaximalEdgeRing(this._startEdge) {
    attachEdges(_startEdge);
  }

  void attachEdges(OverlayEdge startEdge) {
    OverlayEdge? edge = startEdge;
    do {
      if (edge == null) {
        throw TopologyException("Ring edge is null");
      }

      if (edge.getEdgeRingMax() == this) {
        throw TopologyException(
            "Ring edge visited twice at ${edge.getCoordinate()}", edge.getCoordinate());
      }

      if (edge.nextResultMax() == null) {
        throw TopologyException("Ring edge missing at", edge.dest());
      }
      edge.setEdgeRingMax(this);
      edge = edge.nextResultMax();
    } while (edge != startEdge);
  }

  List<OverlayEdgeRing> buildMinimalRings(GeometryFactory geometryFactory) {
    linkMinimalRings();
    List<OverlayEdgeRing> minEdgeRings = [];
    OverlayEdge? e = _startEdge;
    do {
      if (e!.getEdgeRing() == null) {
        OverlayEdgeRing minEr = OverlayEdgeRing(e, geometryFactory);
        minEdgeRings.add(minEr);
      }
      e = e.nextResultMax();
    } while (e != _startEdge);
    return minEdgeRings;
  }

  void linkMinimalRings() {
    OverlayEdge? e = _startEdge;
    do {
      linkMinRingEdgesAtNode(e!, this);
      e = e.nextResultMax();
    } while (e != _startEdge);
  }

  static void linkMinRingEdgesAtNode(OverlayEdge nodeEdge, NgMaximalEdgeRing maxRing) {
    OverlayEdge endOut = nodeEdge;
    OverlayEdge? currMaxRingOut = endOut;
    OverlayEdge? currOut = endOut.oNextOE();
    do {
      if (isAlreadyLinked(currOut!.symOE(), maxRing)) {
        return;
      }

      if (currMaxRingOut == null) {
        currMaxRingOut = selectMaxOutEdge(currOut, maxRing);
      } else {
        currMaxRingOut = linkMaxInEdge(currOut, currMaxRingOut, maxRing);
      }
      currOut = currOut.oNextOE();
    } while (currOut != endOut);
    if (currMaxRingOut != null) {
      throw TopologyException(
          "Unmatched edge found during min-ring linking", nodeEdge.getCoordinate());
    }
  }

  static bool isAlreadyLinked(OverlayEdge edge, NgMaximalEdgeRing maxRing) {
    bool isLinked = (edge.getEdgeRingMax() == maxRing) && edge.isResultLinked();
    return isLinked;
  }

  static OverlayEdge? selectMaxOutEdge(OverlayEdge currOut, NgMaximalEdgeRing maxEdgeRing) {
    if (currOut.getEdgeRingMax() == maxEdgeRing) {
      return currOut;
    }

    return null;
  }

  static OverlayEdge? linkMaxInEdge(
      OverlayEdge currOut, OverlayEdge currMaxRingOut, NgMaximalEdgeRing maxEdgeRing) {
    OverlayEdge currIn = currOut.symOE();
    if (currIn.getEdgeRingMax() != maxEdgeRing) {
      return currMaxRingOut;
    }

    currIn.setNextResult(currMaxRingOut);
    return null;
  }

  Array<Coordinate> getCoordinates() {
    CoordinateList coords = CoordinateList();
    OverlayEdge? edge = _startEdge;
    do {
      coords.add(edge!.orig());
      if (edge.nextResultMax() == null) {
        break;
      }
      edge = edge.nextResultMax();
    } while (edge != _startEdge);
    coords.add(edge!.dest());
    return coords.toCoordinateArray();
  }
}
