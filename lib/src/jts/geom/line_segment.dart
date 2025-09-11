import 'dart:math';

import 'package:d_util/d_util.dart';

import '../../../dts.dart';

class LineSegment implements Comparable<LineSegment> {
  Coordinate p0;
  Coordinate p1;

  LineSegment(this.p0, this.p1);

  LineSegment.of2(double x0, double y0, double x1, double y1) : this(Coordinate(x0, y0), Coordinate(x1, y1));

  LineSegment.of(LineSegment ls) : this(ls.p0, ls.p1);

  LineSegment.empty() : this(Coordinate(), Coordinate());

  Coordinate getCoordinate(int i) {
    if (i == 0) {
      return p0;
    }

    return p1;
  }

  void setCoordinates(LineSegment ls) {
    setCoordinates2(ls.p0, ls.p1);
  }

  void setCoordinates2(Coordinate p0, Coordinate p1) {
    this.p0.x = p0.x;
    this.p0.y = p0.y;
    this.p1.x = p1.x;
    this.p1.y = p1.y;
  }

  double minX() {
    return min(p0.x, p1.x);
  }

  double maxX() {
    return max(p0.x, p1.x);
  }

  double minY() {
    return min(p0.y, p1.y);
  }

  double maxY() {
    return max(p0.y, p1.y);
  }

  double getLength() {
    return p0.distance(p1);
  }

  bool isHorizontal() {
    return p0.y == p1.y;
  }

  bool isVertical() {
    return p0.x == p1.x;
  }

  int orientationIndex2(LineSegment seg) {
    int orient0 = Orientation.index(p0, p1, seg.p0);
    int orient1 = Orientation.index(p0, p1, seg.p1);
    if ((orient0 >= 0) && (orient1 >= 0)) {
      return max(orient0, orient1).toInt();
    }

    if ((orient0 <= 0) && (orient1 <= 0)) {
      return min(orient0, orient1).toInt();
    }

    return 0;
  }

  int orientationIndex(Coordinate p) {
    return Orientation.index(p0, p1, p);
  }

  void reverse() {
    Coordinate temp = p0;
    p0 = p1;
    p1 = temp;
  }

  void normalize() {
    if (p1.compareTo(p0) < 0) reverse();
  }

  double angle() {
    return atan2(p1.y - p0.y, p1.x - p0.x);
  }

  Coordinate midPoint() {
    return midPoint2(p0, p1);
  }

  static Coordinate midPoint2(Coordinate p0, Coordinate p1) {
    return Coordinate((p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
  }

  double distance2(LineSegment ls) {
    return Distance.segmentToSegment(p0, p1, ls.p0, ls.p1);
  }

  double distance(Coordinate p) {
    return Distance.pointToSegment(p, p0, p1);
  }

  double distancePerpendicular(Coordinate p) {
    if (p0.equals2D(p1)) return p0.distance(p);

    return Distance.pointToLinePerpendicular(p, p0, p1);
  }

  double distancePerpendicularOriented(Coordinate p) {
    if (p0.equals2D(p1)) return p0.distance(p);

    double dist = distancePerpendicular(p);
    if (orientationIndex(p) < 0) return -dist;

    return dist;
  }

  Coordinate pointAlong(double segmentLengthFraction) {
    Coordinate coord = p0.create();
    coord.x = p0.x + (segmentLengthFraction * (p1.x - p0.x));
    coord.y = p0.y + (segmentLengthFraction * (p1.y - p0.y));
    return coord;
  }

  Coordinate pointAlongOffset(double segmentLengthFraction, double offsetDistance) {
    double segx = p0.x + (segmentLengthFraction * (p1.x - p0.x));
    double segy = p0.y + (segmentLengthFraction * (p1.y - p0.y));
    double dx = p1.x - p0.x;
    double dy = p1.y - p0.y;
    double len = MathUtil.hypot(dx, dy);
    double ux = 0.0;
    double uy = 0.0;
    if (offsetDistance != 0.0) {
      if (len <= 0.0) {
        throw ("Cannot compute offset from zero-length line segment");
      }

      ux = (offsetDistance * dx) / len;
      uy = (offsetDistance * dy) / len;
    }
    double offsetx = segx - uy;
    double offsety = segy + ux;
    Coordinate coord = p0.create();
    coord.x = offsetx;
    coord.y = offsety;
    return coord;
  }

  double projectionFactor(Coordinate p) {
    if (p == p0) return 0.0;

    if (p == p1) return 1.0;

    double dx = p1.x - p0.x;
    double dy = p1.y - p0.y;
    double len = (dx * dx) + (dy * dy);
    if (len <= 0.0) return double.nan;

    double r = (((p.x - p0.x) * dx) + ((p.y - p0.y) * dy)) / len;
    return r;
  }

  double segmentFraction(Coordinate inputPt) {
    double segFrac = projectionFactor(inputPt);
    if (segFrac < 0.0) {
      segFrac = 0.0;
    } else if ((segFrac > 1.0) || segFrac.isNaN) {
      segFrac = 1.0;
    }

    return segFrac;
  }

  Coordinate project(Coordinate p) {
    if (p == p0 || p == p1) return p.copy();

    double r = projectionFactor(p);
    return project2(p, r);
  }

  Coordinate project2(Coordinate p, double projectionFactor) {
    Coordinate coord = p.copy();
    coord.x = p0.x + (projectionFactor * (p1.x - p0.x));
    coord.y = p0.y + (projectionFactor * (p1.y - p0.y));
    return coord;
  }

  LineSegment? project3(LineSegment seg) {
    double pf0 = projectionFactor(seg.p0);
    double pf1 = projectionFactor(seg.p1);
    if ((pf0 >= 1.0) && (pf1 >= 1.0)) return null;

    if ((pf0 <= 0.0) && (pf1 <= 0.0)) return null;

    Coordinate newp0 = project2(seg.p0, pf0);
    if (pf0 < 0.0) newp0 = p0;

    if (pf0 > 1.0) newp0 = p1;

    Coordinate newp1 = project2(seg.p1, pf1);
    if (pf1 < 0.0) newp1 = p0;

    if (pf1 > 1.0) newp1 = p1;

    return LineSegment(newp0, newp1);
  }

  LineSegment offset(double offsetDistance) {
    Coordinate offset0 = pointAlongOffset(0, offsetDistance);
    Coordinate offset1 = pointAlongOffset(1, offsetDistance);
    return LineSegment(offset0, offset1);
  }

  Coordinate reflect(Coordinate p) {
    double A = p1.y - p0.y;
    double B = p0.x - p1.x;
    double C = (p0.y * (p1.x - p0.x)) - (p0.x * (p1.y - p0.y));
    double a2PlusB2 = (A * A) + (B * B);
    double a2SubB2 = (A * A) - (B * B);
    double x = p.x;
    double y = p.y;
    double rx = (((-a2SubB2 * x) - (2 * A * B * y)) - (2 * A * C)) / a2PlusB2;
    double ry = ((a2SubB2 * y) - (2 * A * B * x) - (2 * B * C)) / a2PlusB2;
    Coordinate coord = p.copy();
    coord.x = rx;
    coord.y = ry;
    return coord;
  }

  Coordinate closestPoint(Coordinate p) {
    double factor = projectionFactor(p);
    if ((factor > 0) && (factor < 1)) {
      return project2(p, factor);
    }
    double dist0 = p0.distance(p);
    double dist1 = p1.distance(p);
    if (dist0 < dist1) return p0;

    return p1;
  }

  List<Coordinate> closestPoints(LineSegment line) {
    Coordinate? intPt = intersection(line);
    if (intPt != null) {
      return [intPt, intPt];
    }
    List<Coordinate> closestPt;
    double minDistance = double.maxFinite;
    double dist;
    Coordinate close00 = closestPoint(line.p0);
    minDistance = close00.distance(line.p0);
    closestPt = [close00, line.p0];

    Coordinate close01 = closestPoint(line.p1);
    dist = close01.distance(line.p1);
    if (dist < minDistance) {
      minDistance = dist;
      closestPt[0] = close01;
      closestPt[1] = line.p1;
    }
    Coordinate close10 = line.closestPoint(p0);
    dist = close10.distance(p0);
    if (dist < minDistance) {
      minDistance = dist;
      closestPt[0] = p0;
      closestPt[1] = close10;
    }
    Coordinate close11 = line.closestPoint(p1);
    dist = close11.distance(p1);
    if (dist < minDistance) {
      minDistance = dist;
      closestPt[0] = p1;
      closestPt[1] = close11;
    }
    return closestPt;
  }

  Coordinate? intersection(LineSegment? line) {
    LineIntersector li = RobustLineIntersector();
    li.computeIntersection2(p0, p1, line!.p0, line.p1);
    if (li.hasIntersection()) {
      return li.getIntersection(0);
    }

    return null;
  }

  Coordinate? lineIntersection(LineSegment line) {
    return Intersection.intersection(p0, p1, line.p0, line.p1);
  }

  LineString? toGeometry(GeometryFactory geomFactory) {
    return geomFactory.createLineString2([p0, p1]);
  }

  int oldHashCode() {
    int bits0 = Double.doubleToLongBits(p0.x);
    bits0 ^= Double.doubleToLongBits(p0.y) * 31;
    int hash0 = ((bits0)) ^ (bits0 >> 32);
    int bits1 = Double.doubleToLongBits(p1.x);
    bits1 ^= Double.doubleToLongBits(p1.y) * 31;
    int hash1 = ((bits1)) ^ (bits1 >> 32);
    return hash0 ^ hash1;
  }

  @override
  int compareTo(LineSegment other) {
    int comp0 = p0.compareTo(other.p0);
    if (comp0 != 0) return comp0;

    return p1.compareTo(other.p1);
  }

  bool equalsTopo(LineSegment other) {
    return (p0 == other.p0 && p1 == other.p1) || (p0 == other.p1 && p1 == other.p0);
  }

  @override
  int get hashCode {
    int hash = 17;
    hash = (hash * 29) + Double.hashCode2(p0.x);
    hash = (hash * 29) + Double.hashCode2(p0.y);
    hash = (hash * 29) + Double.hashCode2(p1.x);
    hash = (hash * 29) + Double.hashCode2(p1.y);
    return hash;
  }

  @override
  bool operator ==(Object other) {
    if ((other is! LineSegment)) {
      return false;
    }
    return p0 == other.p0 && p1 == other.p1;
  }
}
