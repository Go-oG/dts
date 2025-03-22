 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/math/math.dart';

final class Distance {
  Distance._();

  static double segmentToSegment(Coordinate A, Coordinate B, Coordinate C, Coordinate D) {
    if (A.equals(B)) {
      return Distance.pointToSegment(A, C, D);
    }

    if (C.equals(D)) {
      return Distance.pointToSegment(D, A, B);
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
        Distance.pointToSegment(A, C, D),
        Distance.pointToSegment(B, C, D),
        Distance.pointToSegment(C, A, B),
        Distance.pointToSegment(D, A, B),
      );
    }
    return 0.0;
  }

  static double pointToSegmentString(Coordinate p, Array<Coordinate> line) {
    if (line.isEmpty) {
      throw IllegalArgumentException("Line array must contain at least one vertex");
    }

    double minDistance = p.distance(line[0]);
    for (int i = 0; i < (line.length - 1); i++) {
      double dist = Distance.pointToSegment(p, line[i], line[i + 1]);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }
    return minDistance;
  }

  static double pointToSegment(Coordinate p, Coordinate A, Coordinate B) {
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

  static double pointToSegmentSq(Coordinate p, Coordinate A, Coordinate B) {
    if ((A.x == B.x) && (A.y == B.y)) {
      return p.distanceSq(A);
    }

    double len2 = ((B.x - A.x) * (B.x - A.x)) + ((B.y - A.y) * (B.y - A.y));
    double r = (((p.x - A.x) * (B.x - A.x)) + ((p.y - A.y) * (B.y - A.y))) / len2;
    if (r <= 0.0) {
      return p.distanceSq(A);
    }

    if (r >= 1.0) {
      return p.distanceSq(B);
    }

    double s = (((A.y - p.y) * (B.x - A.x)) - ((A.x - p.x) * (B.y - A.y))) / len2;
    return (s * s) * len2;
  }

  static double pointToLinePerpendicular(Coordinate p, Coordinate A, Coordinate B) {
    double len2 = ((B.x - A.x) * (B.x - A.x)) + ((B.y - A.y) * (B.y - A.y));
    double s = (((A.y - p.y) * (B.x - A.x)) - ((A.x - p.x) * (B.y - A.y))) / len2;
    return Math.abs(s) * Math.sqrt(len2);
  }

  static double pointToLinePerpendicularSigned(Coordinate p, Coordinate A, Coordinate B) {
    double len2 = ((B.x - A.x) * (B.x - A.x)) + ((B.y - A.y) * (B.y - A.y));
    double s = (((A.y - p.y) * (B.x - A.x)) - ((A.x - p.x) * (B.y - A.y))) / len2;
    return s * Math.sqrt(len2);
  }
}
