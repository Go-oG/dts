import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';

class RobustClipEnvelopeComputer {
  static Envelope getEnvelopeS(Geometry a, Geometry b, Envelope targetEnv) {
    RobustClipEnvelopeComputer cec = RobustClipEnvelopeComputer(targetEnv);
    cec.add(a);
    cec.add(b);
    return cec.getEnvelope();
  }

  final Envelope _targetEnv;

  late Envelope clipEnv;

  RobustClipEnvelopeComputer(this._targetEnv) {
    clipEnv = _targetEnv.copy();
  }

  Envelope getEnvelope() {
    return clipEnv;
  }

  void add(Geometry? g) {
    if (g == null || g.isEmpty()) return;

    if (g is Polygon) {
      addPolygon(g);
    } else if (g is GeometryCollection) {
      addCollection(g);
    }
  }

  void addCollection(GeometryCollection gc) {
    for (int i = 0; i < gc.getNumGeometries(); i++) {
      Geometry g = gc.getGeometryN(i);
      add(g);
    }
  }

  void addPolygon(Polygon poly) {
    LinearRing shell = poly.getExteriorRing();
    addPolygonRing(shell);
    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      LinearRing hole = poly.getInteriorRingN(i);
      addPolygonRing(hole);
    }
  }

  void addPolygonRing(LinearRing ring) {
    if (ring.isEmpty()) return;

    CoordinateSequence seq = ring.getCoordinateSequence();
    for (int i = 1; i < seq.size(); i++) {
      addSegment(seq.getCoordinate(i - 1), seq.getCoordinate(i));
    }
  }

  void addSegment(Coordinate p1, Coordinate p2) {
    if (intersectsSegment(_targetEnv, p1, p2)) {
      clipEnv.expandToIncludeCoordinate(p1);
      clipEnv.expandToIncludeCoordinate(p2);
    }
  }

  static bool intersectsSegment(Envelope env, Coordinate p1, Coordinate p2) {
    return env.intersectsCoordinates(p1, p2);
  }
}
