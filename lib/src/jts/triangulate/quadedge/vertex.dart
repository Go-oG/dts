import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/hcoordinate.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/math/math.dart';

import 'quad_edge.dart';
import 'triangle_predicate.dart';

class Vertex {
  static const int kLeft = 0;

  static const int kRight = 1;

  static const int kBeyond = 2;

  static const int kBehind = 3;

  static const int kBetween = 4;

  static const int kOrigin = 5;

  static const int kDestination = 6;

  late Coordinate p;

  Vertex(double x, double y) {
    p = Coordinate(x, y);
  }

  Vertex.of2(double x, double y, double z) {
    p = Coordinate(x, y, z);
  }

  Vertex.of(Coordinate coord) {
    p = Coordinate.of(coord);
  }

  double getX()=> p.x;

  double getY()=> p.y;

  double getZ() => p.z;

  void setZ(double z) => p.z = z;

  Coordinate getCoordinate() =>p;

  bool equals(Vertex x) {
    if ((p.x == x.getX()) && (p.y == x.getY())) {
      return true;
    } else {
      return false;
    }
  }

  bool equals2(Vertex x, double tolerance) {
    if (p.distance(x.getCoordinate()) < tolerance) {
      return true;
    } else {
      return false;
    }
  }

  int classify(Vertex p0, Vertex p1) {
    Vertex p2 = this;
    Vertex a = p1.sub(p0);
    Vertex b = p2.sub(p0);
    double sa = a.crossProduct(b);
    if (sa > 0.0) return kLeft;

    if (sa < 0.0) return kRight;

    if (((a.getX() * b.getX()) < 0.0) || ((a.getY() * b.getY()) < 0.0)) return kBehind;

    if (a.magn() < b.magn()) return kBeyond;

    if (p0.equals(p2)) return kOrigin;

    if (p1.equals(p2)) return kDestination;

    return kBetween;
  }

  double crossProduct(Vertex v) {
    return (p.x * v.getY()) - (p.y * v.getX());
  }

  double dot(Vertex v) {
    return (p.x * v.getX()) + (p.y * v.getY());
  }

  Vertex times(double c) {
    return Vertex(c * p.x, c * p.y);
  }

  Vertex sum(Vertex v) {
    return Vertex(p.x + v.getX(), p.y + v.getY());
  }

  Vertex sub(Vertex v) {
    return Vertex(p.x - v.getX(), p.y - v.getY());
  }

  double magn() {
    return MathUtil.hypot(p.x, p.y);
  }

  Vertex cross() {
    return Vertex(p.y, -p.x);
  }

  bool isInCircle(Vertex a, Vertex b, Vertex c) {
    return TrianglePredicate.isInCircleRobust(a.p, b.p, c.p, p);
  }

  bool isCCW(Vertex b, Vertex c) {
    return (((b.p.x - p.x) * (c.p.y - p.y)) - ((b.p.y - p.y) * (c.p.x - p.x))) > 0;
  }

  bool rightOf(QuadEdge e) {
    return isCCW(e.dest(), e.orig());
  }

  bool leftOf(QuadEdge e) {
    return isCCW(e.orig(), e.dest());
  }

  HCoordinate bisector(Vertex a, Vertex b) {
    double dx = b.getX() - a.getX();
    double dy = b.getY() - a.getY();
    HCoordinate l1 = HCoordinate(a.getX() + (dx / 2.0), a.getY() + (dy / 2.0), 1.0);
    HCoordinate l2 = HCoordinate((a.getX() - dy) + (dx / 2.0), (a.getY() + dx) + (dy / 2.0), 1.0);
    return HCoordinate.of2(l1, l2);
  }

  double distance(Vertex v1, Vertex v2) {
    return Math.sqrt(Math.pow(v2.getX() - v1.getX(), 2.0) + Math.pow(v2.getY() - v1.getY(), 2.0));
  }

  double circumRadiusRatio(Vertex b, Vertex c) {
    Vertex x = circleCenter(b, c)!;
    double radius = distance(x, b);
    double edgeLength = distance(this, b);
    double el = distance(b, c);
    if (el < edgeLength) {
      edgeLength = el;
    }
    el = distance(c, this);
    if (el < edgeLength) {
      edgeLength = el;
    }
    return radius / edgeLength;
  }

  Vertex midPoint(Vertex a) {
    double xm = (p.x + a.getX()) / 2.0;
    double ym = (p.y + a.getY()) / 2.0;
    double zm = (p.z + a.getZ()) / 2.0;
    return Vertex.of2(xm, ym, zm);
  }

  Vertex? circleCenter(Vertex b, Vertex c) {
    Vertex a = Vertex(getX(), getY());
    HCoordinate cab = bisector(a, b);
    HCoordinate cbc = bisector(b, c);
    HCoordinate hcc = HCoordinate.of2(cab, cbc);
    Vertex? cc;
    try {
      cc = Vertex(hcc.getX(), hcc.getY());
    } catch (_) {}
    return cc;
  }

  double interpolateZValue(Vertex v0, Vertex v1, Vertex v2) {
    double x0 = v0.getX();
    double y0 = v0.getY();
    double a = v1.getX() - x0;
    double b = v2.getX() - x0;
    double c = v1.getY() - y0;
    double d = v2.getY() - y0;
    double det = (a * d) - (b * c);
    double dx = getX() - x0;
    double dy = getY() - y0;
    double t = ((d * dx) - (b * dy)) / det;
    double u = (((-c) * dx) + (a * dy)) / det;
    double z = (v0.getZ() + (t * (v1.getZ() - v0.getZ()))) + (u * (v2.getZ() - v0.getZ()));
    return z;
  }

  static double interpolateZ2(Coordinate p, Coordinate v0, Coordinate v1, Coordinate v2) {
    double x0 = v0.x;
    double y0 = v0.y;
    double a = v1.x - x0;
    double b = v2.x - x0;
    double c = v1.y - y0;
    double d = v2.y - y0;
    double det = (a * d) - (b * c);
    double dx = p.x - x0;
    double dy = p.y - y0;
    double t = ((d * dx) - (b * dy)) / det;
    double u = (((-c) * dx) + (a * dy)) / det;
    double z = v0.z + (t * (v1.z - v0.z)) + (u * (v2.z - v0.z));
    return z;
  }

  static double interpolateZ(Coordinate p, Coordinate p0, Coordinate p1) {
    double segLen = p0.distance(p1);
    double ptLen = p.distance(p0);
    double dz = p1.z - p0.z;
    double pz = p0.z + (dz * (ptLen / segLen));
    return pz;
  }
}
