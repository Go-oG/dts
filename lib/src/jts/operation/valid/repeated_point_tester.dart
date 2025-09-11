import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/multi_point.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';

class RepeatedPointTester {
  Coordinate? _repeatedCoord;

  Coordinate? getCoordinate() {
    return _repeatedCoord;
  }

  bool hasRepeatedPoint2(Geometry g) {
    if (g.isEmpty()) {
      return false;
    }

    if (g is Point) {
      return false;
    }
    if (g is MultiPoint) {
      return false;
    }
    if (g is LineString) {
      return hasRepeatedPoint(g.getCoordinates());
    }
    if (g is Polygon) {
      return hasRepeatedPoint4(((g)));
    }
    if (g is GeometryCollection) {
      return hasRepeatedPoint3(((g)));
    }

    throw "UnsupportedOperationException ${g.runtimeType}";
  }

  bool hasRepeatedPoint(List<Coordinate> coord) {
    for (int i = 1; i < coord.length; i++) {
      if (coord[i - 1] == coord[i]) {
        _repeatedCoord = coord[i];
        return true;
      }
    }
    return false;
  }

  bool hasRepeatedPoint4(Polygon p) {
    if (hasRepeatedPoint(p.getExteriorRing().getCoordinates())) {
      return true;
    }

    for (int i = 0; i < p.getNumInteriorRing(); i++) {
      if (hasRepeatedPoint(p.getInteriorRingN(i).getCoordinates())) {
        return true;
      }
    }
    return false;
  }

  bool hasRepeatedPoint3(GeometryCollection gc) {
    for (int i = 0; i < gc.getNumGeometries(); i++) {
      Geometry g = gc.getGeometryN(i);
      if (hasRepeatedPoint2(g)) {
        return true;
      }
    }
    return false;
  }
}
