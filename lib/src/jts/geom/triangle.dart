import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/angle.dart';
import 'package:dts/src/jts/algorithm/hcoordinate.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/math/math.dart';

import 'coordinate.dart';

class Triangle {
  static bool isAcute2(Coordinate a, Coordinate b, Coordinate c) {
    if (!Angle.isAcute(a, b, c)) return false;

    if (!Angle.isAcute(b, c, a)) return false;

    if (!Angle.isAcute(c, a, b)) return false;

    return true;
  }

  static bool isCCW2(Coordinate a, Coordinate b, Coordinate c) {
    return Orientation.counterClockwise == Orientation.index(a, b, c);
  }

  static bool intersects(Coordinate a, Coordinate b, Coordinate c, Coordinate p) {
    int exteriorIndex = (isCCW2(a, b, c)) ? Orientation.clockwise : Orientation.counterClockwise;
    if (exteriorIndex == Orientation.index(a, b, p)) return false;

    if (exteriorIndex == Orientation.index(b, c, p)) return false;

    if (exteriorIndex == Orientation.index(c, a, p)) return false;

    return true;
  }

  static HCoordinate perpendicularBisector(Coordinate a, Coordinate b) {
    double dx = b.x - a.x;
    double dy = b.y - a.y;
    HCoordinate l1 = HCoordinate(a.x + (dx / 2.0), a.y + (dy / 2.0), 1.0);
    HCoordinate l2 = HCoordinate((a.x - dy) + (dx / 2.0), (a.y + dx) + (dy / 2.0), 1.0);
    return HCoordinate.of2(l1, l2);
  }

  static double circumradius2(Coordinate a, Coordinate b, Coordinate c) {
    double A = a.distance(b);
    double B = b.distance(c);
    double C = c.distance(a);
    double area = area2(a, b, c);
    if (area == 0.0) return double.infinity;

    return ((A * B) * C) / (4 * area);
  }

  static Coordinate circumcentre2(Coordinate a, Coordinate b, Coordinate c) {
    double cx = c.x;
    double cy = c.y;
    double ax = a.x - cx;
    double ay = a.y - cy;
    double bx = b.x - cx;
    double by = b.y - cy;
    double denom = 2 * det(ax, ay, bx, by);
    double numx = det(ay, (ax * ax) + (ay * ay), by, (bx * bx) + (by * by));
    double numy = det(ax, (ax * ax) + (ay * ay), bx, (bx * bx) + (by * by));
    double ccx = cx - (numx / denom);
    double ccy = cy + (numy / denom);
    return Coordinate(ccx, ccy);
  }

  static Coordinate circumcentreDD(Coordinate a, Coordinate b, Coordinate c) {
    DD ax = DD.valueOf(a.x).subtract2(c.x);
    DD ay = DD.valueOf(a.y).subtract2(c.y);
    DD bx = DD.valueOf(b.x).subtract2(c.x);
    DD by = DD.valueOf(b.y).subtract2(c.y);
    DD denom = DD.determinant(ax, ay, bx, by).multiply2(2);
    DD asqr = ax.sqr().add(ay.sqr());
    DD bsqr = bx.sqr().add(by.sqr());
    DD numx = DD.determinant(ay, asqr, by, bsqr);
    DD numy = DD.determinant(ax, asqr, bx, bsqr);
    double ccx = DD.valueOf(c.x).subtract(numx.divide(denom)).doubleValue();
    double ccy = DD.valueOf(c.y).add(numy.divide(denom)).doubleValue();
    return Coordinate(ccx, ccy);
  }

  static double det(double m00, double m01, double m10, double m11) {
    return (m00 * m11) - (m01 * m10);
  }

  static Coordinate inCentreS(Coordinate a, Coordinate b, Coordinate c) {
    double len0 = b.distance(c);
    double len1 = a.distance(c);
    double len2 = a.distance(b);
    double circum = (len0 + len1) + len2;
    double inCentreX = (((len0 * a.x) + (len1 * b.x)) + (len2 * c.x)) / circum;
    double inCentreY = (((len0 * a.y) + (len1 * b.y)) + (len2 * c.y)) / circum;
    return Coordinate(inCentreX, inCentreY);
  }

  static Coordinate centroidS(Coordinate a, Coordinate b, Coordinate c) {
    double x = ((a.x + b.x) + c.x) / 3;
    double y = ((a.y + b.y) + c.y) / 3;
    return Coordinate(x, y);
  }

  static double length2(Coordinate a, Coordinate b, Coordinate c) {
    return (a.distance(b) + b.distance(c)) + c.distance(a);
  }

  static double longestSideLength2(Coordinate a, Coordinate b, Coordinate c) {
    double lenAB = a.distance(b);
    double lenBC = b.distance(c);
    double lenCA = c.distance(a);
    double maxLen = lenAB;
    if (lenBC > maxLen) maxLen = lenBC;

    if (lenCA > maxLen) maxLen = lenCA;

    return maxLen;
  }

  static Coordinate angleBisector(Coordinate a, Coordinate b, Coordinate c) {
    double len0 = b.distance(a);
    double len2 = b.distance(c);
    double frac = len0 / (len0 + len2);
    double dx = c.x - a.x;
    double dy = c.y - a.y;
    Coordinate splitPt = Coordinate(a.x + (frac * dx), a.y + (frac * dy));
    return splitPt;
  }

  static double area2(Coordinate a, Coordinate b, Coordinate c) {
    return Math.abs((((c.x - a.x) * (b.y - a.y)) - ((b.x - a.x) * (c.y - a.y))) / 2);
  }

  static double signedArea2(Coordinate a, Coordinate b, Coordinate c) {
    return (((c.x - a.x) * (b.y - a.y)) - ((b.x - a.x) * (c.y - a.y))) / 2;
  }

  static double area3D2(Coordinate a, Coordinate b, Coordinate c) {
    double ux = b.x - a.x;
    double uy = b.y - a.y;
    double uz = b.z - a.z;
    double vx = c.x - a.x;
    double vy = c.y - a.y;
    double vz = c.z - a.z;
    double crossx = (uy * vz) - (uz * vy);
    double crossy = (uz * vx) - (ux * vz);
    double crossz = (ux * vy) - (uy * vx);
    double absSq = ((crossx * crossx) + (crossy * crossy)) + (crossz * crossz);
    double area3D = Math.sqrt(absSq) / 2;
    return area3D;
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
    double z = (v0.z + (t * (v1.z - v0.z))) + (u * (v2.z - v0.z));
    return z;
  }

  Coordinate p0;

  Coordinate p1;

  Coordinate p2;

  Triangle(this.p0, this.p1, this.p2);

  Coordinate inCentre() {
    return inCentreS(p0, p1, p2);
  }

  bool isAcute() {
    return isAcute2(p0, p1, p2);
  }

  bool isCCW() {
    return isCCW2(p0, p1, p2);
  }

  Coordinate circumcentre() {
    return circumcentre2(p0, p1, p2);
  }

  double circumradius() {
    return circumradius2(p0, p1, p2);
  }

  Coordinate centroid() {
    return centroidS(p0, p1, p2);
  }

  double length() {
    return length2(p0, p1, p2);
  }

  double longestSideLength() {
    return longestSideLength2(p0, p1, p2);
  }

  double area() {
    return area2(p0, p1, p2);
  }

  double signedArea() {
    return signedArea2(p0, p1, p2);
  }

  double area3D() {
    return area3D2(p0, p1, p2);
  }

  double interpolateZ(Coordinate? p) {
    if (p == null) {
      throw IllegalArgumentException("Supplied point is null.");
    }

    return interpolateZ2(p, p0, p1, p2);
  }
}
