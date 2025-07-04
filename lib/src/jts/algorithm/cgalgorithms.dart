import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/math/math.dart';

import 'point_location.dart';
import 'ray_crossing_counter.dart';

final class CGAlgorithms {
  static const int clockwise = -1;
  static const int right = clockwise;
  static const int counterClockwise = 1;
  static const int left = counterClockwise;
  static const int collinear = 0;
  static const int straight = collinear;

  static int orientationIndex(Coordinate p1, Coordinate p2, Coordinate q) {
    return CGAlgorithmsDD.orientationIndex(p1, p2, q);
  }

  CGAlgorithms._();

  static bool isPointInRing(Coordinate p, Array<Coordinate> ring) {
    return locatePointInRing(p, ring) != Location.exterior;
  }

  static int locatePointInRing(Coordinate p, Array<Coordinate> ring) {
    return RayCrossingCounter.locatePointInRing(p, ring);
  }

  static bool isOnLine(Coordinate p, Array<Coordinate> pt) {
    for (int i = 1; i < pt.length; i++) {
      Coordinate p0 = pt[i - 1];
      Coordinate p1 = pt[i];
      if (PointLocation.isOnSegment(p, p0, p1)) {
        return true;
      }
    }
    return false;
  }

  static bool isCCW(Array<Coordinate> ring) {
    int nPts = ring.length - 1;
    if (nPts < 3) {
      throw IllegalArgumentException(
          "Ring has fewer than 4 points, so orientation cannot be determined");
    }

    Coordinate hiPt = ring[0];
    int hiIndex = 0;
    for (int i = 1; i <= nPts; i++) {
      Coordinate p = ring[i];
      if (p.y > hiPt.y) {
        hiPt = p;
        hiIndex = i;
      }
    }
    int iPrev = hiIndex;
    do {
      iPrev = iPrev - 1;
      if (iPrev < 0) {
        iPrev = nPts;
      }
    } while (ring[iPrev].equals2D(hiPt) && (iPrev != hiIndex));
    int iNext = hiIndex;
    do {
      iNext = (iNext + 1) % nPts;
    } while (ring[iNext].equals2D(hiPt) && (iNext != hiIndex));
    Coordinate prev = ring[iPrev];
    Coordinate next = ring[iNext];
    if ((prev.equals2D(hiPt) || next.equals2D(hiPt)) || prev.equals2D(next)) {
      return false;
    }

    int disc = computeOrientation(prev, hiPt, next);
    bool isCCW;
    if (disc == 0) {
      isCCW = prev.x > next.x;
    } else {
      isCCW = disc > 0;
    }
    return isCCW;
  }

  static int computeOrientation(Coordinate p1, Coordinate p2, Coordinate q) {
    return orientationIndex(p1, p2, q);
  }

  static double distancePointLine2(Coordinate p, Coordinate A, Coordinate B) {
    if ((A.x == B.x) && (A.y == B.y)) {
      return p.distance(A);
    }

    double len2 = ((B.x - A.x) * (B.x - A.x)) + ((B.y - A.y) * (B.y - A.y));
    double r = (((p.x - A.x) * (B.x - A.x)) + ((p.y - A.y) * (B.y - A.y))) / len2;
    if (r <= 0.0) {
      return p.distance(A);
    }

    if (r >= 1.0) {
      return p.distance(B);
    }

    double s = (((A.y - p.y) * (B.x - A.x)) - ((A.x - p.x) * (B.y - A.y))) / len2;
    return Math.abs(s) * Math.sqrt(len2);
  }

  static double distancePointLinePerpendicular(Coordinate p, Coordinate A, Coordinate B) {
    double len2 = ((B.x - A.x) * (B.x - A.x)) + ((B.y - A.y) * (B.y - A.y));
    double s = (((A.y - p.y) * (B.x - A.x)) - ((A.x - p.x) * (B.y - A.y))) / len2;
    return Math.abs(s) * Math.sqrt(len2);
  }

  static double distancePointLine(Coordinate p, Array<Coordinate> line) {
    if (line.length == 0) {
      throw IllegalArgumentException("Line array must contain at least one vertex");
    }

    double minDistance = p.distance(line[0]);
    for (int i = 0; i < (line.length - 1); i++) {
      double dist = distancePointLine2(p, line[i], line[i + 1]);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }
    return minDistance;
  }

  static double distanceLineLine(Coordinate A, Coordinate B, Coordinate C, Coordinate D) {
    if (A == B) {
      return distancePointLine2(A, C, D);
    }

    if (C == D) {
      return distancePointLine2(D, A, B);
    }

    bool noIntersection = false;
    if (!Envelope.intersects4(A, B, C, D)) {
      noIntersection = true;
    } else {
      double denom = ((B.x - A.x) * (D.y - C.y)) - ((B.y - A.y) * (D.x - C.x));
      if (denom == 0) {
        noIntersection = true;
      } else {
        double rNum = ((A.y - C.y) * (D.x - C.x)) - ((A.x - C.x) * (D.y - C.y));
        double sNum = ((A.y - C.y) * (B.x - A.x)) - ((A.x - C.x) * (B.y - A.y));
        double s = sNum / denom;
        double r = rNum / denom;
        if ((((r < 0) || (r > 1)) || (s < 0)) || (s > 1)) {
          noIntersection = true;
        }
      }
    }
    if (noIntersection) {
      return MathUtil.min(
        distancePointLine2(A, C, D),
        distancePointLine2(B, C, D),
        distancePointLine2(C, A, B),
        distancePointLine2(D, A, B),
      );
    }
    return 0.0;
  }

  static double signedArea(Array<Coordinate> ring) {
    if (ring.length < 3) {
      return 0.0;
    }

    double sum = 0.0;
    double x0 = ring[0].x;
    for (int i = 1; i < (ring.length - 1); i++) {
      double x = ring[i].x - x0;
      double y1 = ring[i + 1].y;
      double y2 = ring[i - 1].y;
      sum += x * (y2 - y1);
    }
    return sum / 2.0;
  }

  static double signedArea2(CoordinateSequence ring) {
    int n = ring.size();
    if (n < 3) {
      return 0.0;
    }

    Coordinate p0 = Coordinate();
    Coordinate p1 = Coordinate();
    Coordinate p2 = Coordinate();
    ring.getCoordinate2(0, p1);
    ring.getCoordinate2(1, p2);
    double x0 = p1.x;
    p2.x -= x0;
    double sum = 0.0;
    for (int i = 1; i < (n - 1); i++) {
      p0.y = p1.y;
      p1.x = p2.x;
      p1.y = p2.y;
      ring.getCoordinate2(i + 1, p2);
      p2.x -= x0;
      sum += p1.x * (p0.y - p2.y);
    }
    return sum / 2.0;
  }

  static double length(CoordinateSequence pts) {
    int n = pts.size();
    if (n <= 1) {
      return 0.0;
    }

    double len = 0.0;
    Coordinate p = Coordinate();
    pts.getCoordinate2(0, p);
    double x0 = p.x;
    double y0 = p.y;
    for (int i = 1; i < n; i++) {
      pts.getCoordinate2(i, p);
      double x1 = p.x;
      double y1 = p.y;
      double dx = x1 - x0;
      double dy = y1 - y0;
      len += MathUtil.hypot(dx, dy);
      x0 = x1;
      y0 = y1;
    }
    return len;
  }
}

final class CGAlgorithms3D {
  CGAlgorithms3D._();

  static double distance(Coordinate p0, Coordinate p1) {
    if (Double.isNaN(p0.z) || Double.isNaN(p1.z)) {
      return p0.distance(p1);
    }

    double dx = p0.x - p1.x;
    double dy = p0.y - p1.y;
    double dz = p0.z - p1.z;
    return Math.sqrt(((dx * dx) + (dy * dy)) + (dz * dz));
  }

  static double distancePointSegment(Coordinate p, Coordinate A, Coordinate B) {
    if (A.equals3D(B)) {
      return distance(p, A);
    }

    double len2 =
        (((B.x - A.x) * (B.x - A.x)) + ((B.y - A.y) * (B.y - A.y))) + ((B.z - A.z) * (B.z - A.z));
    if (Double.isNaN(len2)) {
      throw IllegalArgumentException("Ordinates must not be NaN");
    }

    double r = ((((p.x - A.x) * (B.x - A.x)) + ((p.y - A.y) * (B.y - A.y))) +
            ((p.z - A.z) * (B.z - A.z))) /
        len2;
    if (r <= 0.0) {
      return distance(p, A);
    }

    if (r >= 1.0) {
      return distance(p, B);
    }

    double qx = A.x + (r * (B.x - A.x));
    double qy = A.y + (r * (B.y - A.y));
    double qz = A.z + (r * (B.z - A.z));
    double dx = p.x - qx;
    double dy = p.y - qy;
    double dz = p.z - qz;
    return Math.sqrt(((dx * dx) + (dy * dy)) + (dz * dz));
  }

  static double distanceSegmentSegment(Coordinate A, Coordinate B, Coordinate C, Coordinate D) {
    if (A.equals3D(B)) {
      return distancePointSegment(A, C, D);
    }

    if (C.equals3D(B)) {
      return distancePointSegment(C, A, B);
    }

    double a = Vector3D.dot2(A, B, A, B);
    double b = Vector3D.dot2(A, B, C, D);
    double c = Vector3D.dot2(C, D, C, D);
    double d = Vector3D.dot2(A, B, C, A);
    double e = Vector3D.dot2(C, D, C, A);
    double denom = (a * c) - (b * b);
    if (Double.isNaN(denom)) {
      throw IllegalArgumentException("Ordinates must not be NaN");
    }

    double s;
    double t;
    if (denom <= 0.0) {
      s = 0;
      if (b > c) {
        t = d / b;
      } else {
        t = e / c;
      }
    } else {
      s = ((b * e) - (c * d)) / denom;
      t = ((a * e) - (b * d)) / denom;
    }
    if (s < 0) {
      return distancePointSegment(A, C, D);
    }
    if (s > 1) {
      return distancePointSegment(B, C, D);
    }
    if (t < 0) {
      return distancePointSegment(C, A, B);
    }
    if (t > 1) {
      return distancePointSegment(D, A, B);
    }
    double x1 = A.x + (s * (B.x - A.x));
    double y1 = A.y + (s * (B.y - A.y));
    double z1 = A.z + (s * (B.z - A.z));
    double x2 = C.x + (t * (D.x - C.x));
    double y2 = C.y + (t * (D.y - C.y));
    double z2 = C.z + (t * (D.z - C.z));
    return distance(Coordinate(x1, y1, z1), Coordinate(x2, y2, z2));
  }
}

final class CGAlgorithmsDD {
  static final double _dpSafeEpsilon = 1.0E-15;
  CGAlgorithmsDD._();
  static int orientationIndex(Coordinate p1, Coordinate p2, Coordinate q) {
    return orientationIndex2(p1.x, p1.y, p2.x, p2.y, q.x, q.y);
  }

  static int orientationIndex2(
      double p1x, double p1y, double p2x, double p2y, double qx, double qy) {
    int index = _orientationIndexFilter(p1x, p1y, p2x, p2y, qx, qy);
    if (index <= 1) {
      return index;
    }

    DD dx1 = DD.valueOf(p2x).selfAdd2(-p1x);
    DD dy1 = DD.valueOf(p2y).selfAdd2(-p1y);
    DD dx2 = DD.valueOf(qx).selfAdd2(-p2x);
    DD dy2 = DD.valueOf(qy).selfAdd2(-p2y);
    return dx1.selfMultiply(dy2).selfSubtract(dy1.selfMultiply(dx2)).signum();
  }

  static int signOfDet2x2(DD x1, DD y1, DD x2, DD y2) {
    DD det = x1.multiply(y2).selfSubtract(y1.multiply(x2));
    return det.signum();
  }

  static int signOfDet2x22(double dx1, double dy1, double dx2, double dy2) {
    DD x1 = DD.valueOf(dx1);
    DD y1 = DD.valueOf(dy1);
    DD x2 = DD.valueOf(dx2);
    DD y2 = DD.valueOf(dy2);
    DD det = x1.multiply(y2).selfSubtract(y1.multiply(x2));
    return det.signum();
  }

  static int _orientationIndexFilter(
      double pax, double pay, double pbx, double pby, double pcx, double pcy) {
    double detsum;
    double detleft = (pax - pcx) * (pby - pcy);
    double detright = (pay - pcy) * (pbx - pcx);
    double det = detleft - detright;
    if (detleft > 0.0) {
      if (detright <= 0.0) {
        return _signum(det);
      } else {
        detsum = detleft + detright;
      }
    } else if (detleft < 0.0) {
      if (detright >= 0.0) {
        return _signum(det);
      } else {
        detsum = (-detleft) - detright;
      }
    } else {
      return _signum(det);
    }
    double errbound = _dpSafeEpsilon * detsum;
    if ((det >= errbound) || ((-det) >= errbound)) {
      return _signum(det);
    }
    return 2;
  }

  static int _signum(double x) {
    if (x > 0) {
      return 1;
    }

    if (x < 0) {
      return -1;
    }

    return 0;
  }

  static Coordinate? intersection(Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    DD px = DD.valueOf(p1.y).selfSubtract2(p2.y);
    DD py = DD.valueOf(p2.x).selfSubtract2(p1.x);
    DD pw = DD.valueOf(p1.x).selfMultiply2(p2.y).selfSubtract(DD.valueOf(p2.x).selfMultiply2(p1.y));
    DD qx = DD.valueOf(q1.y).selfSubtract2(q2.y);
    DD qy = DD.valueOf(q2.x).selfSubtract2(q1.x);
    DD qw = DD.valueOf(q1.x).selfMultiply2(q2.y).selfSubtract(DD.valueOf(q2.x).selfMultiply2(q1.y));
    DD x = py.multiply(qw).selfSubtract(qy.multiply(pw));
    DD y = qx.multiply(pw).selfSubtract(px.multiply(qw));
    DD w = px.multiply(qy).selfSubtract(qx.multiply(py));
    double xInt = x.selfDivide(w).doubleValue();
    double yInt = y.selfDivide(w).doubleValue();
    if ((Double.isNaN(xInt) || (Double.isInfinite(xInt) || Double.isNaN(yInt))) ||
        Double.isInfinite(yInt)) {
      return null;
    }
    return Coordinate(xInt, yInt);
  }
}
