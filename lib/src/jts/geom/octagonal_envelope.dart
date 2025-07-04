import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/point.dart';

import 'coordinate.dart';
import 'coordinate_list.dart';
import 'coordinate_sequence.dart';
import 'envelope.dart';
import 'geometry.dart';
import 'geometry_component_filter.dart';
import 'geometry_factory.dart';
import 'line_string.dart';
import 'precision_model.dart';

class OctagonalEnvelope {
  static Geometry octagonalEnvelope(Geometry geom) {
    return OctagonalEnvelope.of5(geom).toGeometry(geom.factory);
  }

  static double computeA(double x, double y) {
    return x + y;
  }

  static double computeB(double x, double y) {
    return x - y;
  }

  static final double _SQRT2 = Math.sqrt(2.0);

  double _minX = double.nan;

  late double _maxX;

  late double _minY;

  late double _maxY;

  late double _minA;

  late double _maxA;

  late double _minB;

  late double _maxB;

  OctagonalEnvelope();

  OctagonalEnvelope.of(Coordinate p) {
    expandToInclude(p);
  }

  OctagonalEnvelope.of2(Coordinate p0, Coordinate p1) {
    expandToInclude(p0);
    expandToInclude(p1);
  }

  OctagonalEnvelope.of3(Envelope env) {
    expandToInclude4(env);
  }

  OctagonalEnvelope.of4(OctagonalEnvelope oct) {
    expandToInclude6(oct);
  }

  OctagonalEnvelope.of5(Geometry geom) {
    expandToInclude5(geom);
  }

  double getMinX() {
    return _minX;
  }

  double getMaxX() {
    return _maxX;
  }

  double getMinY() {
    return _minY;
  }

  double getMaxY() {
    return _maxY;
  }

  double getMinA() {
    return _minA;
  }

  double getMaxA() {
    return _maxA;
  }

  double getMinB() {
    return _minB;
  }

  double getMaxB() {
    return _maxB;
  }

  bool isNull() {
    return Double.isNaN(_minX);
  }

  void setToNull() {
    _minX = double.nan;
  }

  void expandToInclude5(Geometry g) {
    g.apply4(BoundingOctagonComponentFilter(this));
  }

  OctagonalEnvelope expandToInclude2(CoordinateSequence seq) {
    for (int i = 0; i < seq.size(); i++) {
      double x = seq.getX(i);
      double y = seq.getY(i);
      expandToInclude3(x, y);
    }
    return this;
  }

  OctagonalEnvelope expandToInclude6(OctagonalEnvelope oct) {
    if (oct.isNull()) return this;

    if (isNull()) {
      _minX = oct._minX;
      _maxX = oct._maxX;
      _minY = oct._minY;
      _maxY = oct._maxY;
      _minA = oct._minA;
      _maxA = oct._maxA;
      _minB = oct._minB;
      _maxB = oct._maxB;
      return this;
    }
    if (oct._minX < _minX) _minX = oct._minX;

    if (oct._maxX > _maxX) _maxX = oct._maxX;

    if (oct._minY < _minY) _minY = oct._minY;

    if (oct._maxY > _maxY) _maxY = oct._maxY;

    if (oct._minA < _minA) _minA = oct._minA;

    if (oct._maxA > _maxA) _maxA = oct._maxA;

    if (oct._minB < _minB) _minB = oct._minB;

    if (oct._maxB > _maxB) _maxB = oct._maxB;

    return this;
  }

  OctagonalEnvelope expandToInclude(Coordinate p) {
    expandToInclude3(p.x, p.y);
    return this;
  }

  OctagonalEnvelope expandToInclude4(Envelope env) {
    expandToInclude3(env.minX, env.minY);
    expandToInclude3(env.minX, env.maxY);
    expandToInclude3(env.maxX, env.minY);
    expandToInclude3(env.maxX, env.maxY);
    return this;
  }

  OctagonalEnvelope expandToInclude3(double x, double y) {
    double A = computeA(x, y);
    double B = computeB(x, y);
    if (isNull()) {
      _minX = x;
      _maxX = x;
      _minY = y;
      _maxY = y;
      _minA = A;
      _maxA = A;
      _minB = B;
      _maxB = B;
    } else {
      if (x < _minX) _minX = x;

      if (x > _maxX) _maxX = x;

      if (y < _minY) _minY = y;

      if (y > _maxY) _maxY = y;

      if (A < _minA) _minA = A;

      if (A > _maxA) _maxA = A;

      if (B < _minB) _minB = B;

      if (B > _maxB) _maxB = B;
    }
    return this;
  }

  void expandBy(double distance) {
    if (isNull()) return;

    double diagonalDistance = _SQRT2 * distance;
    _minX -= distance;
    _maxX += distance;
    _minY -= distance;
    _maxY += distance;
    _minA -= diagonalDistance;
    _maxA += diagonalDistance;
    _minB -= diagonalDistance;
    _maxB += diagonalDistance;
    if (!isValid()) setToNull();
  }

  bool isValid() {
    if (isNull()) return true;

    return (((_minX <= _maxX) && (_minY <= _maxY)) && (_minA <= _maxA)) && (_minB <= _maxB);
  }

  bool intersects2(OctagonalEnvelope other) {
    if (isNull() || other.isNull()) {
      return false;
    }
    if (_minX > other._maxX) return false;

    if (_maxX < other._minX) return false;

    if (_minY > other._maxY) return false;

    if (_maxY < other._minY) return false;

    if (_minA > other._maxA) return false;

    if (_maxA < other._minA) return false;

    if (_minB > other._maxB) return false;

    if (_maxB < other._minB) return false;

    return true;
  }

  bool intersects(Coordinate p) {
    if (_minX > p.x) return false;

    if (_maxX < p.x) return false;

    if (_minY > p.y) return false;

    if (_maxY < p.y) return false;

    double A = computeA(p.x, p.y);
    double B = computeB(p.x, p.y);
    if (_minA > A) return false;

    if (_maxA < A) return false;

    if (_minB > B) return false;

    if (_maxB < B) return false;

    return true;
  }

  bool contains(OctagonalEnvelope other) {
    if (isNull() || other.isNull()) {
      return false;
    }
    return (((((((other._minX >= _minX) && (other._maxX <= _maxX)) && (other._minY >= _minY)) &&
                        (other._maxY <= _maxY)) &&
                    (other._minA >= _minA)) &&
                (other._maxA <= _maxA)) &&
            (other._minB >= _minB)) &&
        (other._maxB <= _maxB);
  }

  Geometry toGeometry(GeometryFactory geomFactory) {
    if (isNull()) {
      return geomFactory.createPoint();
    }
    Coordinate px00 = Coordinate(_minX, _minA - _minX);
    Coordinate px01 = Coordinate(_minX, _minX - _minB);
    Coordinate px10 = Coordinate(_maxX, _maxX - _maxB);
    Coordinate px11 = Coordinate(_maxX, _maxA - _maxX);
    Coordinate py00 = Coordinate(_minA - _minY, _minY);
    Coordinate py01 = Coordinate(_minY + _maxB, _minY);
    Coordinate py10 = Coordinate(_maxY + _minB, _maxY);
    Coordinate py11 = Coordinate(_maxA - _maxY, _maxY);
    PrecisionModel pm = geomFactory.getPrecisionModel();
    pm.makePrecise(px00);
    pm.makePrecise(px01);
    pm.makePrecise(px10);
    pm.makePrecise(px11);
    pm.makePrecise(py00);
    pm.makePrecise(py01);
    pm.makePrecise(py10);
    pm.makePrecise(py11);
    CoordinateList coordList = CoordinateList();
    coordList.add3(px00, false);
    coordList.add3(px01, false);
    coordList.add3(py10, false);
    coordList.add3(py11, false);
    coordList.add3(px11, false);
    coordList.add3(px10, false);
    coordList.add3(py01, false);
    coordList.add3(py00, false);
    if (coordList.size == 1) {
      return geomFactory.createPoint2(px00);
    }
    if (coordList.size == 2) {
      Array<Coordinate> pts = coordList.toCoordinateArray();
      return geomFactory.createLineString2(pts);
    }
    coordList.add3(px00, false);
    Array<Coordinate> pts = coordList.toCoordinateArray();
    return geomFactory.createPolygon(geomFactory.createLinearRings(pts));
  }
}

class BoundingOctagonComponentFilter implements GeometryComponentFilter {
  OctagonalEnvelope oe;

  BoundingOctagonComponentFilter(this.oe);

  @override
  void filter(Geometry geom) {
    if (geom is LineString) {
      oe.expandToInclude2((geom).getCoordinateSequence());
    } else if (geom is Point) {
      oe.expandToInclude2(geom.getCoordinateSequence());
    }
  }
}
