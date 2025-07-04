import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'orientation.dart';

class Centroid {
  static Coordinate getCentroidS(Geometry geom) {
    return Centroid(geom).getCentroid()!;
  }

  final _triangleCent3 = Coordinate();
  final _cg3 = Coordinate();
  final _lineCentSum = Coordinate();
  final _ptCentSum = Coordinate();

  double _areaSum2 = 0;
  double _totalLength = 0.0;
  int _ptCount = 0;

  Coordinate? _areaBasePt;

  Centroid(Geometry geom) {
    _add(geom);
  }

  void _add(Geometry geom) {
    if (geom.isEmpty()) {
      return;
    }

    if (geom is Point) {
      _addPoint(geom.getCoordinate()!);
    } else if (geom is LineString) {
      _addLineSegments(geom.getCoordinates());
    } else if (geom is Polygon) {
      _add2(geom);
    } else if (geom is GeometryCollection) {
      for (int i = 0; i < geom.getNumGeometries(); i++) {
        _add(geom.getGeometryN(i));
      }
    }
  }

  Coordinate? getCentroid() {
    Coordinate cent = Coordinate();
    if (Math.abs(_areaSum2) > 0.0) {
      cent.x = (_cg3.x / 3) / _areaSum2;
      cent.y = (_cg3.y / 3) / _areaSum2;
    } else if (_totalLength > 0.0) {
      cent.x = _lineCentSum.x / _totalLength;
      cent.y = _lineCentSum.y / _totalLength;
    } else if (_ptCount > 0) {
      cent.x = _ptCentSum.x / _ptCount;
      cent.y = _ptCentSum.y / _ptCount;
    } else {
      return null;
    }
    return cent;
  }

  void _setAreaBasePoint(Coordinate basePt) {
    _areaBasePt = basePt;
  }

  void _add2(Polygon poly) {
    _addShell(poly.getExteriorRing().getCoordinates());
    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      _addHole(poly.getInteriorRingN(i).getCoordinates());
    }
  }

  void _addShell(Array<Coordinate> pts) {
    if (pts.length > 0) {
      _setAreaBasePoint(pts[0]);
    }

    bool isPositiveArea = !Orientation.isCCW(pts);
    for (int i = 0; i < (pts.length - 1); i++) {
      _addTriangle(_areaBasePt!, pts[i], pts[i + 1], isPositiveArea);
    }
    _addLineSegments(pts);
  }

  void _addHole(Array<Coordinate> pts) {
    bool isPositiveArea = Orientation.isCCW(pts);
    for (int i = 0; i < (pts.length - 1); i++) {
      _addTriangle(_areaBasePt!, pts[i], pts[i + 1], isPositiveArea);
    }
    _addLineSegments(pts);
  }

  void _addTriangle(Coordinate p0, Coordinate p1, Coordinate p2, bool isPositiveArea) {
    double sign = (isPositiveArea) ? 1.0 : -1.0;
    _centroid3(p0, p1, p2, _triangleCent3);
    double area2 = _area2(p0, p1, p2);
    _cg3.x += (sign * area2) * _triangleCent3.x;
    _cg3.y += (sign * area2) * _triangleCent3.y;
    _areaSum2 += sign * area2;
  }

  static void _centroid3(Coordinate p1, Coordinate p2, Coordinate p3, Coordinate c) {
    c.x = (p1.x + p2.x) + p3.x;
    c.y = (p1.y + p2.y) + p3.y;
    return;
  }

  static double _area2(Coordinate p1, Coordinate p2, Coordinate p3) {
    return ((p2.x - p1.x) * (p3.y - p1.y)) - ((p3.x - p1.x) * (p2.y - p1.y));
  }

  void _addLineSegments(Array<Coordinate> pts) {
    double lineLen = 0.0;
    for (int i = 0; i < (pts.length - 1); i++) {
      double segmentLen = pts[i].distance(pts[i + 1]);
      if (segmentLen == 0.0) {
        continue;
      }

      lineLen += segmentLen;
      double midx = (pts[i].x + pts[i + 1].x) / 2;
      _lineCentSum.x += segmentLen * midx;
      double midy = (pts[i].y + pts[i + 1].y) / 2;
      _lineCentSum.y += segmentLen * midy;
    }
    _totalLength += lineLen;
    if ((lineLen == 0.0) && (pts.length > 0)) {
      _addPoint(pts[0]);
    }
  }

  void _addPoint(Coordinate pt) {
    _ptCount += 1;
    _ptCentSum.x += pt.x;
    _ptCentSum.y += pt.y;
  }
}
