import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/triangle.dart';
import 'package:dts/src/jts/math/math.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'angle.dart';

class MinimumBoundingCircle {
  final Geometry _input;

  Array<Coordinate>? _extremalPts;

  Coordinate? _centre;

  double _radius = 0.0;

  MinimumBoundingCircle(this._input);

  Geometry getCircle() {
    _compute();

    Point centrePoint = _input.factory.createPoint2(_centre);
    if (_radius == 0.0) {
      return centrePoint;
    }

    return centrePoint.buffer(_radius);
  }

  Geometry getMaximumDiameter() {
    _compute();
    switch (_extremalPts!.length) {
      case 0:
        return _input.factory.createLineString();
      case 1:
        return _input.factory.createPoint2(_centre);
      case 2:
        return _input.factory.createLineString2([_extremalPts![0], _extremalPts![1]].toArray());
      default:
        Array<Coordinate> maxDiameter = _farthestPoints(_extremalPts!);
        return _input.factory.createLineString2(maxDiameter);
    }
  }

  Geometry getFarthestPoints() {
    return getMaximumDiameter();
  }

  static Array<Coordinate> _farthestPoints(Array<Coordinate> pts) {
    double dist01 = pts[0].distance(pts[1]);
    double dist12 = pts[1].distance(pts[2]);
    double dist20 = pts[2].distance(pts[0]);
    if ((dist01 >= dist12) && (dist01 >= dist20)) {
      return [pts[0], pts[1]].toArray();
    }
    if ((dist12 >= dist01) && (dist12 >= dist20)) {
      return [pts[1], pts[2]].toArray();
    }
    return [pts[2], pts[0]].toArray();
  }

  Geometry getDiameter() {
    _compute();
    switch (_extremalPts!.length) {
      case 0:
        return _input.factory.createLineString();
      case 1:
        return _input.factory.createPoint2(_centre);
    }
    Coordinate p0 = _extremalPts![0];
    Coordinate p1 = _extremalPts![1];
    return _input.factory.createLineString2([p0, p1].toArray());
  }

  Array<Coordinate> getExtremalPoints() {
    _compute();
    return _extremalPts!;
  }

  Coordinate getCentre() {
    _compute();
    return _centre!;
  }

  double getRadius() {
    _compute();
    return _radius;
  }

  void _computeCentre() {
    switch (_extremalPts!.length) {
      case 0:
        _centre = null;
        break;
      case 1:
        _centre = _extremalPts![0];
        break;
      case 2:
        _centre = Coordinate(
          (_extremalPts![0].x + _extremalPts![1].x) / 2.0,
          (_extremalPts![0].y + _extremalPts![1].y) / 2.0,
        );
        break;
      case 3:
        _centre = Triangle.circumcentre2(_extremalPts![0], _extremalPts![1], _extremalPts![2]);
        break;
    }
  }

  void _compute() {
    if (_extremalPts != null) {
      return;
    }

    _computeCirclePoints();
    _computeCentre();
    _radius = _centre!.distance(_extremalPts![0]);
  }

  void _computeCirclePoints() {
    if (_input.isEmpty()) {
      _extremalPts = Array<Coordinate>(0);
      return;
    }
    if (_input.getNumPoints() == 1) {
      Array<Coordinate> pts = _input.getCoordinates();
      _extremalPts = [Coordinate.of(pts[0])].toArray();
      return;
    }
    Geometry convexHull = _input.convexHull();
    Array<Coordinate> hullPts = convexHull.getCoordinates();
    Array<Coordinate> pts = hullPts;
    if (hullPts[0].equals2D(hullPts[hullPts.length - 1])) {
      pts = Array<Coordinate>(hullPts.length - 1);
      CoordinateArrays.copyDeep2(hullPts, 0, pts, 0, hullPts.length - 1);
    }
    if (pts.length <= 2) {
      _extremalPts = CoordinateArrays.copyDeep(pts);
      return;
    }
    Coordinate P = _lowestPoint(pts);
    Coordinate Q = _pointWitMinAngleWithX(pts, P)!;
    for (int i = 0; i < pts.length; i++) {
      Coordinate R = _pointWithMinAngleWithSegment(pts, P, Q)!;
      if (Angle.isObtuse(P, R, Q)) {
        _extremalPts = [Coordinate.of(P), Coordinate.of(Q)].toArray();
        return;
      } else if (Angle.isObtuse(R, P, Q)) {
        P = R;
        continue;
      } else if (Angle.isObtuse(R, Q, P)) {
        Q = R;
        continue;
      } else {
        _extremalPts = [Coordinate.of(P), Coordinate.of(Q), Coordinate.of(R)].toArray();
        return;
      }
    }
    Assert.shouldNeverReachHere2("Logic failure in Minimum Bounding Circle algorithm!");
  }

  static Coordinate _lowestPoint(Array<Coordinate> pts) {
    Coordinate min = pts[0];
    for (int i = 1; i < pts.length; i++) {
      if (pts[i].y < min.y) {
        min = pts[i];
      }
    }
    return min;
  }

  static Coordinate? _pointWitMinAngleWithX(Array<Coordinate> pts, Coordinate P) {
    double minSin = double.maxFinite;
    Coordinate? minAngPt;
    for (int i = 0; i < pts.length; i++) {
      Coordinate p = pts[i];
      if (p == P) {
        continue;
      }

      double dx = p.x - P.x;
      double dy = p.y - P.y;
      if (dy < 0) {
        dy = -dy;
      }

      double len = MathUtil.hypot(dx, dy);
      double sin = dy / len;
      if (sin < minSin) {
        minSin = sin;
        minAngPt = p;
      }
    }
    return minAngPt;
  }

  static Coordinate? _pointWithMinAngleWithSegment(
      Array<Coordinate> pts, Coordinate P, Coordinate Q) {
    double minAng = double.maxFinite;
    Coordinate? minAngPt;
    for (int i = 0; i < pts.length; i++) {
      Coordinate p = pts[i];
      if (p == P) {
        continue;
      }

      if (p == Q) {
        continue;
      }

      double ang = Angle.angleBetween(P, p, Q);
      if (ang < minAng) {
        minAng = ang;
        minAngPt = p;
      }
    }
    return minAngPt;
  }
}
