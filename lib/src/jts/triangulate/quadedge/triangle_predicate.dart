import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/triangle.dart';
import 'package:dts/src/jts/math/math.dart';

class TrianglePredicate {
  static bool isInCircleNonRobust(Coordinate a, Coordinate b, Coordinate c, Coordinate p) {
    bool isInCircle =
        ((((((a.x * a.x) + (a.y * a.y)) * triArea(b, c, p)) - (((b.x * b.x) + (b.y * b.y)) * triArea(a, c, p))) +
                (((c.x * c.x) + (c.y * c.y)) * triArea(a, b, p))) -
            (((p.x * p.x) + (p.y * p.y)) * triArea(a, b, c))) >
        0;
    return isInCircle;
  }

  static bool isInCircleNormalized(Coordinate a, Coordinate b, Coordinate c, Coordinate p) {
    double adx = a.x - p.x;
    double ady = a.y - p.y;
    double bdx = b.x - p.x;
    double bdy = b.y - p.y;
    double cdx = c.x - p.x;
    double cdy = c.y - p.y;
    double abdet = (adx * bdy) - (bdx * ady);
    double bcdet = (bdx * cdy) - (cdx * bdy);
    double cadet = (cdx * ady) - (adx * cdy);
    double alift = (adx * adx) + (ady * ady);
    double blift = (bdx * bdx) + (bdy * bdy);
    double clift = (cdx * cdx) + (cdy * cdy);
    double disc = ((alift * bcdet) + (blift * cadet)) + (clift * abdet);
    return disc > 0;
  }

  static double triArea(Coordinate a, Coordinate b, Coordinate c) {
    return ((b.x - a.x) * (c.y - a.y)) - ((b.y - a.y) * (c.x - a.x));
  }

  static bool isInCircleRobust(Coordinate a, Coordinate b, Coordinate c, Coordinate p) {
    return isInCircleNormalized(a, b, c, p);
  }

  static bool isInCircleDDSlow(Coordinate a, Coordinate b, Coordinate c, Coordinate p) {
    DD px = DD.valueOf(p.x);
    DD py = DD.valueOf(p.y);
    DD ax = DD.valueOf(a.x);
    DD ay = DD.valueOf(a.y);
    DD bx = DD.valueOf(b.x);
    DD by = DD.valueOf(b.y);
    DD cx = DD.valueOf(c.x);
    DD cy = DD.valueOf(c.y);
    DD aTerm = ax.multiply(ax).add(ay.multiply(ay)).multiply(triAreaDDSlow(bx, by, cx, cy, px, py));
    DD bTerm = bx.multiply(bx).add(by.multiply(by)).multiply(triAreaDDSlow(ax, ay, cx, cy, px, py));
    DD cTerm = cx.multiply(cx).add(cy.multiply(cy)).multiply(triAreaDDSlow(ax, ay, bx, by, px, py));
    DD pTerm = px.multiply(px).add(py.multiply(py)).multiply(triAreaDDSlow(ax, ay, bx, by, cx, cy));
    DD sum = aTerm.subtract(bTerm).add(cTerm).subtract(pTerm);
    bool isInCircle = sum.doubleValue() > 0;
    return isInCircle;
  }

  static DD triAreaDDSlow(DD ax, DD ay, DD bx, DD by, DD cx, DD cy) {
    return bx.subtract(ax).multiply(cy.subtract(ay)).subtract(by.subtract(ay).multiply(cx.subtract(ax)));
  }

  static bool isInCircleDDFast(Coordinate a, Coordinate b, Coordinate c, Coordinate p) {
    DD aTerm = DD.sqrS(a.x).selfAdd(DD.sqrS(a.y)).selfMultiply(triAreaDDFast(b, c, p));
    DD bTerm = DD.sqrS(b.x).selfAdd(DD.sqrS(b.y)).selfMultiply(triAreaDDFast(a, c, p));
    DD cTerm = DD.sqrS(c.x).selfAdd(DD.sqrS(c.y)).selfMultiply(triAreaDDFast(a, b, p));
    DD pTerm = DD.sqrS(p.x).selfAdd(DD.sqrS(p.y)).selfMultiply(triAreaDDFast(a, b, c));
    DD sum = aTerm.selfSubtract(bTerm).selfAdd(cTerm).selfSubtract(pTerm);
    bool isInCircle = sum.doubleValue() > 0;
    return isInCircle;
  }

  static DD triAreaDDFast(Coordinate a, Coordinate b, Coordinate c) {
    DD t1 = DD.valueOf(b.x).selfSubtract2(a.x).selfMultiply(DD.valueOf(c.y).selfSubtract2(a.y));
    DD t2 = DD.valueOf(b.y).selfSubtract2(a.y).selfMultiply(DD.valueOf(c.x).selfSubtract2(a.x));
    return t1.selfSubtract(t2);
  }

  static bool isInCircleDDNormalized(Coordinate a, Coordinate b, Coordinate c, Coordinate p) {
    DD adx = DD.valueOf(a.x).selfSubtract2(p.x);
    DD ady = DD.valueOf(a.y).selfSubtract2(p.y);
    DD bdx = DD.valueOf(b.x).selfSubtract2(p.x);
    DD bdy = DD.valueOf(b.y).selfSubtract2(p.y);
    DD cdx = DD.valueOf(c.x).selfSubtract2(p.x);
    DD cdy = DD.valueOf(c.y).selfSubtract2(p.y);
    DD abdet = adx.multiply(bdy).selfSubtract(bdx.multiply(ady));
    DD bcdet = bdx.multiply(cdy).selfSubtract(cdx.multiply(bdy));
    DD cadet = cdx.multiply(ady).selfSubtract(adx.multiply(cdy));
    DD alift = adx.multiply(adx).selfAdd(ady.multiply(ady));
    DD blift = bdx.multiply(bdx).selfAdd(bdy.multiply(bdy));
    DD clift = cdx.multiply(cdx).selfAdd(cdy.multiply(cdy));
    DD sum = alift.selfMultiply(bcdet).selfAdd(blift.selfMultiply(cadet)).selfAdd(clift.selfMultiply(abdet));
    bool isInCircle = sum.doubleValue() > 0;
    return isInCircle;
  }

  static bool isInCircleCC(Coordinate a, Coordinate b, Coordinate c, Coordinate p) {
    Coordinate cc = Triangle.circumcentre2(a, b, c);
    double ccRadius = a.distance(cc);
    double pRadiusDiff = p.distance(cc) - ccRadius;
    return pRadiusDiff <= 0;
  }
}
