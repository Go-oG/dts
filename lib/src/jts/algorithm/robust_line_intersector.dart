import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';

import 'distance.dart';
import 'intersection.dart';
import 'line_intersector.dart';
import 'orientation.dart';

class RobustLineIntersector extends LineIntersector {
  @override
  void computeIntersection(Coordinate p, Coordinate p1, Coordinate p2) {
    isProper = false;
    if (Envelope.intersects3(p1, p2, p)) {
      if ((Orientation.index(p1, p2, p) == 0) && (Orientation.index(p2, p1, p) == 0)) {
        isProper = true;
        if (p == p1 || p == p2) {
          isProper = false;
        }
        result = LineIntersector.kPointIntersection;
        return;
      }
    }
    result = LineIntersector.kNoIntersection;
  }

  @override
  int computeIntersect(Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    isProper = false;
    if (!Envelope.intersects4(p1, p2, q1, q2)) {
      return LineIntersector.kNoIntersection;
    }

    int Pq1 = Orientation.index(p1, p2, q1);
    int Pq2 = Orientation.index(p1, p2, q2);
    if (((Pq1 > 0) && (Pq2 > 0)) || ((Pq1 < 0) && (Pq2 < 0))) {
      return LineIntersector.kNoIntersection;
    }
    int Qp1 = Orientation.index(q1, q2, p1);
    int Qp2 = Orientation.index(q1, q2, p2);
    if (((Qp1 > 0) && (Qp2 > 0)) || ((Qp1 < 0) && (Qp2 < 0))) {
      return LineIntersector.kNoIntersection;
    }
    bool collinear = (((Pq1 == 0) && (Pq2 == 0)) && (Qp1 == 0)) && (Qp2 == 0);
    if (collinear) {
      return _computeCollinearIntersection(p1, p2, q1, q2);
    }
    Coordinate? p;
    double z = double.nan;
    if ((((Pq1 == 0) || (Pq2 == 0)) || (Qp1 == 0)) || (Qp2 == 0)) {
      isProper = false;
      if (p1.equals2D(q1)) {
        p = p1;
        z = _zGet(p1, q1);
      } else if (p1.equals2D(q2)) {
        p = p1;
        z = _zGet(p1, q2);
      } else if (p2.equals2D(q1)) {
        p = p2;
        z = _zGet(p2, q1);
      } else if (p2.equals2D(q2)) {
        p = p2;
        z = _zGet(p2, q2);
      } else if (Pq1 == 0) {
        p = q1;
        z = _zGetOrInterpolate(q1, p1, p2);
      } else if (Pq2 == 0) {
        p = q2;
        z = _zGetOrInterpolate(q2, p1, p2);
      } else if (Qp1 == 0) {
        p = p1;
        z = _zGetOrInterpolate(p1, q1, q2);
      } else if (Qp2 == 0) {
        p = p2;
        z = _zGetOrInterpolate(p2, q1, q2);
      }
    } else {
      isProper = true;
      p = _intersection(p1, p2, q1, q2);
      z = _zInterpolate2(p, p1, p2, q1, q2);
    }
    intPt[0] = _copyWithZ(p!, z);
    return LineIntersector.kPointIntersection;
  }

  int _computeCollinearIntersection(Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    bool q1inP = Envelope.intersects3(p1, p2, q1);
    bool q2inP = Envelope.intersects3(p1, p2, q2);
    bool p1inQ = Envelope.intersects3(q1, q2, p1);
    bool p2inQ = Envelope.intersects3(q1, q2, p2);
    if (q1inP && q2inP) {
      intPt[0] = _copyWithZInterpolate(q1, p1, p2);
      intPt[1] = _copyWithZInterpolate(q2, p1, p2);
      return LineIntersector.kCollinearIntersection;
    }
    if (p1inQ && p2inQ) {
      intPt[0] = _copyWithZInterpolate(p1, q1, q2);
      intPt[1] = _copyWithZInterpolate(p2, q1, q2);
      return LineIntersector.kCollinearIntersection;
    }
    if (q1inP && p1inQ) {
      intPt[0] = _copyWithZInterpolate(q1, p1, p2);
      intPt[1] = _copyWithZInterpolate(p1, q1, q2);
      return (q1 == p1 && !q2inP) && (!p2inQ)
          ? LineIntersector.kPointIntersection
          : LineIntersector.kCollinearIntersection;
    }
    if (q1inP && p2inQ) {
      intPt[0] = _copyWithZInterpolate(q1, p1, p2);
      intPt[1] = _copyWithZInterpolate(p2, q1, q2);
      return (q1 == p2 && !q2inP) && (!p1inQ)
          ? LineIntersector.kPointIntersection
          : LineIntersector.kCollinearIntersection;
    }
    if (q2inP && p1inQ) {
      intPt[0] = _copyWithZInterpolate(q2, p1, p2);
      intPt[1] = _copyWithZInterpolate(p1, q1, q2);
      return (q2 == p1 && (!q1inP)) && (!p2inQ)
          ? LineIntersector.kPointIntersection
          : LineIntersector.kCollinearIntersection;
    }
    if (q2inP && p2inQ) {
      intPt[0] = _copyWithZInterpolate(q2, p1, p2);
      intPt[1] = _copyWithZInterpolate(p2, q1, q2);
      return (q2 == p2 && (!q1inP)) && (!p1inQ)
          ? LineIntersector.kPointIntersection
          : LineIntersector.kCollinearIntersection;
    }
    return LineIntersector.kNoIntersection;
  }

  static Coordinate _copyWithZInterpolate(Coordinate p, Coordinate p1, Coordinate p2) {
    return _copyWithZ(p, _zGetOrInterpolate(p, p1, p2));
  }

  static Coordinate _copyWithZ(Coordinate p, double z) {
    Coordinate pCopy = _copy(p);
    if ((!Double.isNaN(z)) && Coordinates.hasZ(pCopy)) {
      pCopy.z = (z);
    }
    return pCopy;
  }

  static Coordinate _copy(Coordinate p) {
    return p.copy();
  }

  Coordinate _intersection(Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    Coordinate intPt = _intersectionSafe(p1, p2, q1, q2);
    if (!_isInSegmentEnvelopes(intPt)) {
      intPt = _copy(_nearestEndpoint(p1, p2, q1, q2));
    }
    if (precisionModel != null) {
      precisionModel!.makePrecise(intPt);
    }
    return intPt;
  }

  Coordinate _intersectionSafe(Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    Coordinate? intPt = Intersection.intersection(p1, p2, q1, q2);
    intPt ??= _nearestEndpoint(p1, p2, q1, q2);
    return intPt;
  }

  bool _isInSegmentEnvelopes(Coordinate intPt) {
    Envelope env0 = Envelope.of(inputLines[0][0], inputLines[0][1]);
    Envelope env1 = Envelope.of(inputLines[1][0], inputLines[1][1]);
    return env0.containsCoordinate(intPt) && env1.containsCoordinate(intPt);
  }

  static Coordinate _nearestEndpoint(Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    Coordinate nearestPt = p1;
    double minDist = Distance.pointToSegment(p1, q1, q2);
    double dist = Distance.pointToSegment(p2, q1, q2);
    if (dist < minDist) {
      minDist = dist;
      nearestPt = p2;
    }
    dist = Distance.pointToSegment(q1, p1, p2);
    if (dist < minDist) {
      minDist = dist;
      nearestPt = q1;
    }
    dist = Distance.pointToSegment(q2, p1, p2);
    if (dist < minDist) {
      minDist = dist;
      nearestPt = q2;
    }
    return nearestPt;
  }

  static double _zGet(Coordinate p, Coordinate q) {
    double z = p.z;
    if (Double.isNaN(z)) {
      z = q.z;
    }
    return z;
  }

  static double _zGetOrInterpolate(Coordinate p, Coordinate p1, Coordinate p2) {
    double z = p.z;
    if (!Double.isNaN(z)) {
      return z;
    }
    return _zInterpolate(p, p1, p2);
  }

  static double _zInterpolate(Coordinate p, Coordinate p1, Coordinate p2) {
    double p1z = p1.z;
    double p2z = p2.z;
    if (Double.isNaN(p1z)) {
      return p2z;
    }
    if (Double.isNaN(p2z)) {
      return p1z;
    }
    if (p.equals2D(p1)) {
      return p1z;
    }
    if (p.equals2D(p2)) {
      return p2z;
    }
    double dz = p2z - p1z;
    if (dz == 0.0) {
      return p1z;
    }
    double dx = p2.x - p1.x;
    double dy = p2.y - p1.y;
    double seglen = (dx * dx) + (dy * dy);
    double xoff = p.x - p1.x;
    double yoff = p.y - p1.y;
    double plen = (xoff * xoff) + (yoff * yoff);
    double frac = Math.sqrt(plen / seglen);
    double zoff = dz * frac;
    double zInterpolated = p1z + zoff;
    return zInterpolated;
  }

  static double _zInterpolate2(
      Coordinate p, Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    double zp = _zInterpolate(p, p1, p2);
    double zq = _zInterpolate(p, q1, q2);
    if (Double.isNaN(zp)) {
      return zq;
    }
    if (Double.isNaN(zq)) {
      return zp;
    }
    return (zp + zq) / 2.0;
  }
}
