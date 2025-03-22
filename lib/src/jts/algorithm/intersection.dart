 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

import 'cgalgorithms.dart';
import 'distance.dart';
import 'orientation.dart';

final class Intersection {
  Intersection._();
  static Coordinate? intersection(Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    return CGAlgorithmsDD.intersection(p1, p2, q1, q2);
  }

  static Coordinate? _intersectionFP(Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    double minX0 = (p1.x < p2.x) ? p1.x : p2.x;
    double minY0 = (p1.y < p2.y) ? p1.y : p2.y;
    double maxX0 = (p1.x > p2.x) ? p1.x : p2.x;
    double maxY0 = (p1.y > p2.y) ? p1.y : p2.y;
    double minX1 = (q1.x < q2.x) ? q1.x : q2.x;
    double minY1 = (q1.y < q2.y) ? q1.y : q2.y;
    double maxX1 = (q1.x > q2.x) ? q1.x : q2.x;
    double maxY1 = (q1.y > q2.y) ? q1.y : q2.y;
    double intMinX = (minX0 > minX1) ? minX0 : minX1;
    double intMaxX = (maxX0 < maxX1) ? maxX0 : maxX1;
    double intMinY = (minY0 > minY1) ? minY0 : minY1;
    double intMaxY = (maxY0 < maxY1) ? maxY0 : maxY1;
    double midx = (intMinX + intMaxX) / 2.0;
    double midy = (intMinY + intMaxY) / 2.0;
    double p1x = p1.x - midx;
    double p1y = p1.y - midy;
    double p2x = p2.x - midx;
    double p2y = p2.y - midy;
    double q1x = q1.x - midx;
    double q1y = q1.y - midy;
    double q2x = q2.x - midx;
    double q2y = q2.y - midy;
    double px = p1y - p2y;
    double py = p2x - p1x;
    double pw = (p1x * p2y) - (p2x * p1y);
    double qx = q1y - q2y;
    double qy = q2x - q1x;
    double qw = (q1x * q2y) - (q2x * q1y);
    double x = (py * qw) - (qy * pw);
    double y = (qx * pw) - (px * qw);
    double w = (px * qy) - (qx * py);
    double xInt = x / w;
    double yInt = y / w;
    if ((Double.isNaN(xInt) || (Double.isInfinite(xInt) || Double.isNaN(yInt))) || Double.isInfinite(yInt)) {
      return null;
    }
    return Coordinate(xInt + midx, yInt + midy);
  }

  static Coordinate? lineSegment(Coordinate line1, Coordinate line2, Coordinate seg1, Coordinate seg2) {
    int orientS1 = Orientation.index(line1, line2, seg1);
    if (orientS1 == 0) {
      return seg1.copy();
    }

    int orientS2 = Orientation.index(line1, line2, seg2);
    if (orientS2 == 0) {
      return seg2.copy();
    }

    if (((orientS1 > 0) && (orientS2 > 0)) || ((orientS1 < 0) && (orientS2 < 0))) {
      return null;
    }
    Coordinate? intPt = intersection(line1, line2, seg1, seg2);
    if (intPt != null) {
      return intPt;
    }

    double dist1 = Distance.pointToLinePerpendicular(seg1, line1, line2);
    double dist2 = Distance.pointToLinePerpendicular(seg2, line1, line2);
    if (dist1 < dist2) {
      return seg1.copy();
    }

    return seg2;
  }
}
