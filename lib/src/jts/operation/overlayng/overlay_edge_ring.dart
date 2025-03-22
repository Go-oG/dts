 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';

import 'overlay_edge.dart';

class OverlayEdgeRing {
  OverlayEdge startEdge;

  LinearRing? ring;

  bool isHole = false;

  late Array<Coordinate> _ringPts;

  IndexedPointInAreaLocator? _locator;

  OverlayEdgeRing? _shell;

  final List<OverlayEdgeRing> _holes = [];

  OverlayEdgeRing(this.startEdge, GeometryFactory geometryFactory) {
    _ringPts = computeRingPts(startEdge);
    computeRing(_ringPts, geometryFactory);
  }

  LinearRing? getRing() {
    return ring;
  }

  Envelope getEnvelope() {
    return ring!.getEnvelopeInternal();
  }

  void setShell(OverlayEdgeRing? shell) {
    _shell = shell;
    if (shell != null) {
      shell.addHole(this);
    }
  }

  bool hasShell() {
    return _shell != null;
  }

  OverlayEdgeRing? getShell() {
    if (isHole) {
      return _shell;
    }

    return this;
  }

  void addHole(OverlayEdgeRing ring) {
    _holes.add(ring);
  }

  Array<Coordinate> computeRingPts(OverlayEdge start) {
    OverlayEdge? edge = start;
    CoordinateList pts = CoordinateList();
    do {
      if (edge!.getEdgeRing() == this) {
        throw TopologyException(
          "Edge visited twice during ring-building at ${edge.getCoordinate()}",
          edge.getCoordinate(),
        );
      }

      edge.addCoordinates(pts);
      edge.setEdgeRing(this);
      if (edge.nextResult() == null) {
        throw TopologyException("Found null edge in ring", edge.dest());
      }

      edge = edge.nextResult();
    } while (edge != start);
    pts.closeRing();
    return pts.toCoordinateArray();
  }

  void computeRing(Array<Coordinate> ringPts, GeometryFactory geometryFactory) {
    if (ring != null) {
      return;
    }
    ring = geometryFactory.createLinearRing2(ringPts);
    isHole = Orientation.isCCW(ring!.getCoordinates());
  }

  Array<Coordinate> getCoordinates() {
    return _ringPts;
  }

  OverlayEdgeRing? findEdgeRingContaining(List<OverlayEdgeRing> erList) {
    OverlayEdgeRing? minContainingRing;
    for (OverlayEdgeRing edgeRing in erList) {
      if (edgeRing.contains(this)) {
        if ((minContainingRing == null) || minContainingRing.getEnvelope().contains3(edgeRing.getEnvelope())) {
          minContainingRing = edgeRing;
        }
      }
    }
    return minContainingRing;
  }

  PointOnGeometryLocator getLocator() {
    _locator ??= IndexedPointInAreaLocator(getRing());
    return _locator!;
  }

  int locate(Coordinate pt) {
    return getLocator().locate(pt);
  }

  bool contains(OverlayEdgeRing ring) {
    Envelope env = getEnvelope();
    Envelope testEnv = ring.getEnvelope();
    if (!env.containsProperly(testEnv)) return false;

    return isPointInOrOut(ring);
  }

  bool isPointInOrOut(OverlayEdgeRing ring) {
    for (Coordinate pt in ring.getCoordinates()) {
      int loc = locate(pt);
      if (loc == Location.interior) {
        return true;
      }
      if (loc == Location.exterior) {
        return false;
      }
    }
    return false;
  }

  Coordinate getCoordinate() {
    return _ringPts[0];
  }

  Polygon toPolygon(GeometryFactory factory) {
    Array<LinearRing>? holeLR;
    holeLR = Array(_holes.length);
    for (int i = 0; i < _holes.length; i++) {
      holeLR[i] = (_holes[i].getRing() as LinearRing);
    }
    return factory.createPolygon(ring, holeLR);
  }

  OverlayEdge getEdge() {
    return startEdge;
  }
}
