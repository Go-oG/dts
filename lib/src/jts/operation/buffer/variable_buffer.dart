import 'dart:math';

import 'package:dts/src/jts/algorithm/angle.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'buffer_parameters.dart';

class VariableBuffer {
  static const int _kMinCapSegLenFactor = 4;

  static const double _kSnapTrigTol = 1.0E-6;

  static Geometry buffer(
      LineString line, double startDistance, double endDistance) {
    List<double> distance = interpolate(line, startDistance, endDistance);
    VariableBuffer vb = VariableBuffer(line, distance);
    return vb.getResult();
  }

  static Geometry buffer3(LineString line, double startDistance,
      double midDistance, double endDistance) {
    List<double> distance =
        interpolate2(line, startDistance, midDistance, endDistance);
    VariableBuffer vb = VariableBuffer(line, distance);
    return vb.getResult();
  }

  static Geometry buffer2(LineString line, List<double> distance) {
    VariableBuffer vb = VariableBuffer(line, distance);
    return vb.getResult();
  }

  static List<double> interpolate(
      LineString line, double startValue, double endValue) {
    startValue = startValue.abs();
    endValue = endValue.abs();
    List<double> values = List.filled(line.getNumPoints(), 0);
    values[0] = startValue;
    values[values.length - 1] = endValue;
    double totalLen = line.getLength();
    List<Coordinate> pts = line.getCoordinates();
    double currLen = 0;
    for (int i = 1; i < (values.length - 1); i++) {
      double segLen = pts[i].distance(pts[i - 1]);
      currLen += segLen;
      double lenFrac = currLen / totalLen;
      double delta = lenFrac * (endValue - startValue);
      values[i] = startValue + delta;
    }
    return values;
  }

  static List<double> interpolate2(
      LineString line, double startValue, double midValue, double endValue) {
    startValue = startValue.abs();
    midValue = midValue.abs();
    endValue = endValue.abs();
    List<double> values = List.filled(line.getNumPoints(), 0);
    values[0] = startValue;
    values[values.length - 1] = endValue;
    List<Coordinate> pts = line.getCoordinates();
    double lineLen = line.getLength();
    int midIndex = indexAtLength(pts, lineLen / 2);
    double delMidStart = midValue - startValue;
    double delEndMid = endValue - midValue;
    double lenSM = length(pts, 0, midIndex);
    double currLen = 0;
    for (int i = 1; i <= midIndex; i++) {
      double segLen = pts[i].distance(pts[i - 1]);
      currLen += segLen;
      double lenFrac = currLen / lenSM;
      double val = startValue + (lenFrac * delMidStart);
      values[i] = val;
    }
    double lenME = length(pts, midIndex, pts.length - 1);
    currLen = 0;
    for (int i = midIndex + 1; i < (values.length - 1); i++) {
      double segLen = pts[i].distance(pts[i - 1]);
      currLen += segLen;
      double lenFrac = currLen / lenME;
      double val = midValue + (lenFrac * delEndMid);
      values[i] = val;
    }
    return values;
  }

  static int indexAtLength(List<Coordinate> pts, double targetLen) {
    double len = 0;
    for (int i = 1; i < pts.length; i++) {
      len += pts[i].distance(pts[i - 1]);
      if (len > targetLen) return i;
    }
    return pts.length - 1;
  }

  static double length(List<Coordinate> pts, int i1, int i2) {
    double len = 0;
    for (int i = i1 + 1; i <= i2; i++) {
      len += pts[i].distance(pts[i - 1]);
    }
    return len;
  }

  final LineString _line;

  final List<double> _distance;

  late GeometryFactory geomFactory;

  final int _quadrantSegs = BufferParameters.kDefaultQuadrantSegments;

  VariableBuffer(this._line, this._distance) {
    geomFactory = _line.factory;
    if (_distance.length != _line.getNumPoints()) {
      throw ArgumentError(
          "Number of distances is not equal to number of vertices");
    }
  }

  Geometry getResult() {
    List<Geometry> parts = [];
    List<Coordinate> pts = _line.getCoordinates();
    for (int i = 1; i < pts.length; i++) {
      double dist0 = _distance[i - 1];
      double dist1 = _distance[i];
      if ((dist0 > 0) || (dist1 > 0)) {
        Polygon? poly = segmentBuffer(pts[i - 1], pts[i], dist0, dist1);
        if (poly != null) parts.add(poly);
      }
    }
    GeometryCollection partsGeom = geomFactory.createGeomCollection(parts);
    Geometry buffer = partsGeom.union()!;
    if (buffer.isEmpty()) {
      return geomFactory.createPolygon();
    }
    return buffer;
  }

  Polygon? segmentBuffer(
      Coordinate p0, Coordinate p1, double dist0, double dist1) {
    if ((dist0 <= 0) && (dist1 <= 0)) return null;

    if (dist0 > dist1) {
      return segmentBufferOriented(p1, p0, dist1, dist0);
    }
    return segmentBufferOriented(p0, p1, dist0, dist1);
  }

  Polygon segmentBufferOriented(
      Coordinate p0, Coordinate p1, double dist0, double dist1) {
    LineSegment? tangent = outerTangent(p0, dist0, p1, dist1);
    if (tangent == null) {
      Coordinate center = p0;
      double dist = dist0;
      if (dist1 > dist0) {
        center = p1;
        dist = dist1;
      }
      return circle(center, dist)!;
    }
    LineSegment tangentReflect = reflect(tangent, p0, p1, dist0);
    CoordinateList coords = CoordinateList();
    addCap(p1, dist1, tangent.p1, tangentReflect.p1, coords);
    addCap(p0, dist0, tangentReflect.p0, tangent.p0, coords);
    coords.closeRing();
    return geomFactory.createPolygon3(coords.toCoordinateList());
  }

  LineSegment reflect(
      LineSegment seg, Coordinate p0, Coordinate p1, double dist0) {
    LineSegment line = LineSegment(p0, p1);
    Coordinate r0 = line.reflect(seg.p0);
    Coordinate r1 = line.reflect(seg.p1);
    if (dist0 == 0) r0 = p0.copy();

    return LineSegment(r0, r1);
  }

  Polygon? circle(Coordinate center, double radius) {
    if (radius <= 0) return null;

    int nPts = 4 * _quadrantSegs;
    List<Coordinate> pts = [];
    double angInc = (pi / 2) / _quadrantSegs;
    for (int i = 0; i < nPts; i++) {
      pts.add(projectPolar(center, radius, i * angInc));
    }
    pts.add(pts[0].copy());
    return geomFactory.createPolygon3(pts.toList());
  }

  void addCap(Coordinate p, double r, Coordinate t1, Coordinate t2,
      CoordinateList coords) {
    if (r == 0) {
      coords.add3(p.copy(), false);
      return;
    }
    coords.add3(t1, false);
    double angStart = Angle.angle2(p, t1);
    double angEnd = Angle.angle2(p, t2);
    if (angStart < angEnd) angStart += 2 * pi;

    int indexStart = capAngleIndex(angStart);
    int indexEnd = capAngleIndex(angEnd);
    double capSegLen = (r * 2) * sin((pi / 4) / _quadrantSegs);
    double minSegLen = capSegLen / _kMinCapSegLenFactor;
    for (int i = indexStart; i >= indexEnd; i--) {
      double ang = capAngle(i);
      Coordinate capPt = projectPolar(p, r, ang);
      bool isCapPointHighQuality = true;
      if ((i == indexStart) &&
          (Orientation.clockwise != Orientation.index(p, t1, capPt))) {
        isCapPointHighQuality = false;
      } else if ((i == indexEnd) &&
          (Orientation.counterClockwise != Orientation.index(p, t2, capPt))) {
        isCapPointHighQuality = false;
      }
      if (capPt.distance(t1) < minSegLen) {
        isCapPointHighQuality = false;
      } else if (capPt.distance(t2) < minSegLen) {
        isCapPointHighQuality = false;
      }
      if (isCapPointHighQuality) {
        coords.add3(capPt, false);
      }
    }
    coords.add3(t2, false);
  }

  double capAngle(int index) {
    double capSegAng = (pi / 2) / _quadrantSegs;
    return index * capSegAng;
  }

  int capAngleIndex(double ang) {
    double capSegAng = (pi / 2) / _quadrantSegs;
    int index = ((ang / capSegAng).toInt());
    return index;
  }

  static LineSegment? outerTangent(
      Coordinate c1, double r1, Coordinate c2, double r2) {
    if (r1 > r2) {
      LineSegment seg = outerTangent(c2, r2, c1, r1)!;
      return LineSegment(seg.p1, seg.p0);
    }
    double x1 = c1.x;
    double y1 = c1.y;
    double x2 = c2.x;
    double y2 = c2.y;
    double a3 = -atan2(y2 - y1, x2 - x1);
    double dr = r2 - r1;
    double d = sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)));
    double a2 = asin(dr / d);
    if (a2.isNaN) return null;

    double a1 = a3 - a2;
    double aa = (pi / 2) - a1;
    double x3 = x1 + (r1 * cos(aa));
    double y3 = y1 + (r1 * sin(aa));
    double x4 = x2 + (r2 * cos(aa));
    double y4 = y2 + (r2 * sin(aa));
    return LineSegment.of2(x3, y3, x4, y4);
  }

  static Coordinate projectPolar(Coordinate p, double r, double ang) {
    double x = p.x + (r * snapTrig(cos(ang)));
    double y = p.y + (r * snapTrig(sin(ang)));
    return Coordinate(x, y);
  }

  static double snapTrig(double x) {
    if (x > (1 - _kSnapTrigTol)) return 1;

    if (x < ((-1) + _kSnapTrigTol)) return -1;

    if (x.abs() < _kSnapTrigTol) return 0;

    return x;
  }
}
