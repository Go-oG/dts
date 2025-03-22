 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/angle.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/util/geometry_mapper.dart';

class CubicBezierCurve {
  static Geometry bezierCurve(Geometry geom, double alpha) {
    CubicBezierCurve curve = CubicBezierCurve(geom, alpha);
    return curve.getResult();
  }

  static Geometry bezierCurve3(Geometry geom, double alpha, double skew) {
    CubicBezierCurve curve = CubicBezierCurve.of(geom, alpha, skew);
    return curve.getResult();
  }

  static Geometry controlPoints(Geometry geom, double alpha) {
    CubicBezierCurve curve = CubicBezierCurve(geom, alpha);
    return curve.getControlPoints();
  }

  static Geometry controlPoints2(Geometry geom, double alpha, double skew) {
    CubicBezierCurve curve = CubicBezierCurve.of(geom, alpha, skew);
    return curve.getControlPoints();
  }

  static Geometry bezierCurve2(Geometry geom, Geometry controlPoints) {
    CubicBezierCurve curve = CubicBezierCurve.of2(geom, controlPoints);
    return curve.getResult();
  }

  final double _minSegmentLength = 0.0;

  final int _numVerticesPerSegment = 16;

  Geometry inputGeom;

  double alpha = -1;

  double _skew = 0;

  Geometry? _controlPoints;

  late final GeometryFactory _geomFactory;

  late Array<Coordinate> _bezierCurvePts;

  late Array<Array<double>> _interpolationParam;

  int _controlPointIndex = 0;

  CubicBezierCurve(this.inputGeom, this.alpha) {
    _geomFactory = inputGeom.factory;
    if (alpha < 0.0) {
      alpha = 0;
    }
  }

  CubicBezierCurve.of(this.inputGeom, this.alpha, this._skew) {
    _geomFactory = inputGeom.factory;
    if (alpha < 0.0) {
      alpha = 0;
    }
  }

  CubicBezierCurve.of2(this.inputGeom, this._controlPoints) {
    _geomFactory = inputGeom.factory;
  }

  Geometry getResult() {
    _bezierCurvePts = Array(_numVerticesPerSegment);
    _interpolationParam = computeInterpolationParameters(_numVerticesPerSegment);

    return GeometryMapper.flatMap(
      inputGeom,
      1,
      MapOpNormal((geom) {
        if (geom is LineString) {
          return bezierLine(geom);
        }
        if (geom is Polygon) {
          return bezierPolygon(geom);
        }
        return geom.copy();
      }),
    );
  }

  Geometry getControlPoints() {
    _bezierCurvePts = Array(_numVerticesPerSegment);
    _interpolationParam = computeInterpolationParameters(_numVerticesPerSegment);
    return GeometryMapper.flatMap(
      inputGeom,
      1,
      MapOpNormal((geom) {
        if (geom is LineString) {
          Array<Coordinate> control = controlPoints4(geom.getCoordinates(), false);
          return geom.factory.createLineString2(control);
        }
        if (geom is Polygon) {
          Polygon poly = geom;
          Array<Coordinate> control = controlPoints4(poly.getExteriorRing().getCoordinates(), true);
          return geom.factory.createLineString2(control);
        }
        return geom.copy();
      }),
    );
  }

  LineString bezierLine(LineString ls) {
    if (ls.getNumPoints() <= 2) {
      return ls.copy();
    }

    Array<Coordinate> coords = ls.getCoordinates();
    CoordinateList curvePts = bezierCurve4(coords, false);
    curvePts.add3(coords[coords.length - 1].copy(), false);
    return _geomFactory.createLineString2(curvePts.toCoordinateArray());
  }

  LinearRing bezierRing(LinearRing ring) {
    Array<Coordinate> coords = ring.getCoordinates();
    CoordinateList curvePts = bezierCurve4(coords, true);
    curvePts.closeRing();
    return _geomFactory.createLinearRing2(curvePts.toCoordinateArray());
  }

  Polygon bezierPolygon(Polygon poly) {
    LinearRing shell = bezierRing(poly.getExteriorRing());
    Array<LinearRing>? holes;
    if (poly.getNumInteriorRing() > 0) {
      holes = Array(poly.getNumInteriorRing());
      for (int i = 0; i < poly.getNumInteriorRing(); i++) {
        holes[i] = bezierRing(poly.getInteriorRingN(i));
      }
    }
    return _geomFactory.createPolygon(shell, holes);
  }

  CoordinateList bezierCurve4(Array<Coordinate> coords, bool isRing) {
    CoordinateList curvePts = CoordinateList();
    if (coords.length <= 2) {
      return curvePts;
    }

    Array<Coordinate> control = controlPoints4(coords, isRing);
    for (int i = 0; i < (coords.length - 1); i++) {
      int ctrlIndex = 2 * i;
      addCurve(coords[i], coords[i + 1], control[ctrlIndex], control[ctrlIndex + 1], curvePts);
    }
    return curvePts;
  }

  Array<Coordinate> controlPoints4(Array<Coordinate> coords, bool isRing) {
    if (_controlPoints != null) {
      if (_controlPointIndex >= _controlPoints!.getNumGeometries()) {
        throw IllegalArgumentException("Too few control point elements");
      }
      Geometry ctrlPtsGeom = _controlPoints!.getGeometryN(_controlPointIndex++);
      Array<Coordinate> ctrlPts = ctrlPtsGeom.getCoordinates();
      int expectedNum1 = (2 * coords.length) - 2;
      int expectedNum2 = (isRing) ? coords.length - 1 : coords.length;
      if ((expectedNum1 != ctrlPts.length) && (expectedNum2 != ctrlPts.length)) {
        throw ((
          "Wrong number of control points for element %d - expected %d or %d, found %d",
          _controlPointIndex - 1,
          expectedNum1,
          expectedNum2,
          ctrlPts.length,
        ));
      }
      return ctrlPts;
    }
    return controlPoints3(coords, isRing, alpha, _skew);
  }

  void addCurve(Coordinate p0, Coordinate p1, Coordinate ctrl0, Coordinate crtl1, CoordinateList curvePts) {
    double len = p0.distance(p1);
    if (len < _minSegmentLength) {
      curvePts.add(Coordinate.of(p0));
    } else {
      cubicBezier(p0, p1, ctrl0, crtl1, _interpolationParam, _bezierCurvePts);
      for (int i = 0; i < (_bezierCurvePts.length - 1); i++) {
        curvePts.add3(_bezierCurvePts[i], false);
      }
    }
  }

  static const double _CIRCLE_LEN_FACTOR = 3.0 / 8.0;

  static Array<Coordinate> controlPoints3(Array<Coordinate> coords, bool isRing, double alpha, double skew) {
    int N = coords.length;
    int start = 1;
    int end = N - 1;
    if (isRing) {
      N = coords.length - 1;
      start = 0;
      end = N;
    }
    int nControl = (2 * coords.length) - 2;
    Array<Coordinate> ctrl = Array(nControl);
    for (int i = start; i < end; i++) {
      int iprev = (i == 0) ? N - 1 : i - 1;
      Coordinate v0 = coords[iprev];
      Coordinate v1 = coords[i];
      Coordinate v2 = coords[i + 1];
      double interiorAng = Angle.angleBetweenOriented(v0, v1, v2);
      double orient = interiorAng.sign;
      double angBisect = Angle.bisector(v0, v1, v2);
      double ang0 = angBisect - (orient * Angle.piOver2);
      double ang1 = angBisect + (orient * Angle.piOver2);
      double dist0 = v1.distance(v0);
      double dist1 = v1.distance(v2);
      double lenBase = Math.min(dist0, dist1).toDouble();
      double intAngAbs = Math.abs(interiorAng);
      double sharpnessFactor = (intAngAbs >= Angle.piOver2) ? 1 : intAngAbs / Angle.piOver2;
      double len = ((alpha * _CIRCLE_LEN_FACTOR) * sharpnessFactor) * lenBase;
      double stretch0 = 1;
      double stretch1 = 1;
      if (skew != 0) {
        double stretch = Math.abs(dist0 - dist1) / Math.max(dist0, dist1);
        int skewIndex = (dist0 > dist1) ? 0 : 1;
        if (skew < 0) {
          skewIndex = 1 - skewIndex;
        }

        if (skewIndex == 0) {
          stretch0 += Math.abs(skew) * stretch;
        } else {
          stretch1 += Math.abs(skew) * stretch;
        }
      }
      Coordinate ctl0 = Angle.project(v1, ang0, stretch0 * len);
      Coordinate ctl1 = Angle.project(v1, ang1, stretch1 * len);
      int index = (2 * i) - 1;
      int i0 = (index < 0) ? nControl - 1 : index;
      ctrl[i0] = ctl0;
      ctrl[index + 1] = ctl1;
    }
    if (!isRing) {
      setLineEndControlPoints(coords, ctrl);
    }
    return ctrl;
  }

  static void setLineEndControlPoints(Array<Coordinate> coords, Array<Coordinate> ctrl) {
    int N = ctrl.length;
    ctrl[0] = mirrorControlPoint(ctrl[1], coords[1], coords[0]);
    ctrl[N - 1] = mirrorControlPoint(ctrl[N - 2], coords[coords.length - 1], coords[coords.length - 2]);
  }

  static Coordinate aimedControlPoint(Coordinate c, Coordinate p1, Coordinate p0) {
    double len = p1.distance(c);
    double ang = Angle.angle2(p0, p1);
    return Angle.project(p0, ang, len);
  }

  static Coordinate mirrorControlPoint(Coordinate c, Coordinate p0, Coordinate p1) {
    double vlinex = p1.x - p0.x;
    double vliney = p1.y - p0.y;
    double vrotx = -vliney;
    double vroty = vlinex;
    double midx = (p0.x + p1.x) / 2;
    double midy = (p0.y + p1.y) / 2;
    return reflectPointInLine(c, Coordinate(midx, midy), Coordinate(midx + vrotx, midy + vroty));
  }

  static Coordinate reflectPointInLine(Coordinate p, Coordinate p0, Coordinate p1) {
    double vx = p1.x - p0.x;
    double vy = p1.y - p0.y;
    double x = p0.x - p.x;
    double y = p0.y - p.y;
    double r = 1 / ((vx * vx) + (vy * vy));
    double rx = p.x + (2 * ((x - (((x * vx) * vx) * r)) - (((y * vx) * vy) * r)));
    double ry = p.y + (2 * ((y - (((y * vy) * vy) * r)) - (((x * vx) * vy) * r)));
    return Coordinate(rx, ry);
  }

  void cubicBezier(
    final Coordinate p0,
    final Coordinate p1,
    final Coordinate ctrl1,
    final Coordinate ctrl2,
    Array<Array<double>> param,
    Array<Coordinate> curve,
  ) {
    int n = curve.length;
    curve[0] = Coordinate.of(p0);
    curve[n - 1] = Coordinate.of(p1);
    for (int i = 1; i < (n - 1); i++) {
      Coordinate c = Coordinate();
      double sum = ((param[i][0] + param[i][1]) + param[i][2]) + param[i][3];
      c.x = (((param[i][0] * p0.x) + (param[i][1] * ctrl1.x)) + (param[i][2] * ctrl2.x)) + (param[i][3] * p1.x);
      c.x /= sum;
      c.y = (((param[i][0] * p0.y) + (param[i][1] * ctrl1.y)) + (param[i][2] * ctrl2.y)) + (param[i][3] * p1.y);
      c.y /= sum;
      curve[i] = c;
    }
  }

  static Array<Array<double>> computeInterpolationParameters(int n) {
    Array<Array<double>> param = Array.matrix2(n, 4);
    for (int i = 0; i < n; i++) {
      double t = (i) / (n - 1);
      double tc = 1.0 - t;
      param[i][0] = (tc * tc) * tc;
      param[i][1] = ((3.0 * tc) * tc) * t;
      param[i][2] = ((3.0 * tc) * t) * t;
      param[i][3] = (t * t) * t;
    }
    return param;
  }
}
