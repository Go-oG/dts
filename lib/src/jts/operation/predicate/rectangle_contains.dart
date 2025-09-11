import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';

class RectangleContains {
  static bool containsS(Polygon rectangle, Geometry b) {
    return RectangleContains(rectangle).contains(b);
  }

  late final Envelope rectEnv;

  RectangleContains(Polygon rectangle) {
    rectEnv = rectangle.getEnvelopeInternal();
  }

  bool contains(Geometry geom) {
    if (!rectEnv.contains(geom.getEnvelopeInternal())) return false;

    if (isContainedInBoundary(geom)) return false;

    return true;
  }

  bool isContainedInBoundary(Geometry geom) {
    if (geom is Polygon) return false;

    if (geom is Point) return isPointContainedInBoundary2(geom);

    if (geom is LineString) return isLineStringContainedInBoundary(geom);

    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry comp = geom.getGeometryN(i);
      if (!isContainedInBoundary(comp)) return false;
    }
    return true;
  }

  bool isPointContainedInBoundary2(Point point) {
    return isPointContainedInBoundary(point.getCoordinate()!);
  }

  bool isPointContainedInBoundary(Coordinate pt) {
    return (((pt.x == rectEnv.minX) || (pt.x == rectEnv.maxX)) ||
            (pt.y == rectEnv.minY)) ||
        (pt.y == rectEnv.maxY);
  }

  bool isLineStringContainedInBoundary(LineString line) {
    CoordinateSequence seq = line.getCoordinateSequence();
    Coordinate p0 = Coordinate();
    Coordinate p1 = Coordinate();
    for (int i = 0; i < (seq.size() - 1); i++) {
      seq.getCoordinate2(i, p0);
      seq.getCoordinate2(i + 1, p1);
      if (!isLineSegmentContainedInBoundary(p0, p1)) return false;
    }
    return true;
  }

  bool isLineSegmentContainedInBoundary(Coordinate p0, Coordinate p1) {
    if (p0 == p1) return isPointContainedInBoundary(p0);

    if (p0.x == p1.x) {
      if ((p0.x == rectEnv.minX) || (p0.x == rectEnv.maxX)) return true;
    } else if (p0.y == p1.y) {
      if ((p0.y == rectEnv.minY) || (p0.y == rectEnv.maxY)) return true;
    }
    return false;
  }
}
