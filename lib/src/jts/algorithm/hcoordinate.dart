import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

final class HCoordinate {
  static Coordinate intersection(
      Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    double px = p1.y - p2.y;
    double py = p2.x - p1.x;
    double pw = (p1.x * p2.y) - (p2.x * p1.y);
    double qx = q1.y - q2.y;
    double qy = q2.x - q1.x;
    double qw = (q1.x * q2.y) - (q2.x * q1.y);
    double x = (py * qw) - (qy * pw);
    double y = (qx * pw) - (px * qw);
    double w = (px * qy) - (qx * py);
    double xInt = x / w;
    double yInt = y / w;
    if ((Double.isNaN(xInt) ||
            (Double.isInfinite(xInt) || Double.isNaN(yInt))) ||
        Double.isInfinite(yInt)) {
      throw "NotRepresentableException";
    }
    return Coordinate(xInt, yInt);
  }

  late final double x;
  late final double y;
  late final double w;

  HCoordinate([this.x = 0.0, this.y = 0.0, this.w = 1.0]);

  HCoordinate.of(Coordinate p) : this(p.x, p.y, 1.0);

  HCoordinate.of2(HCoordinate p1, HCoordinate p2) {
    x = (p1.y * p2.w) - (p2.y * p1.w);
    y = (p2.x * p1.w) - (p1.x * p2.w);
    w = (p1.x * p2.y) - (p2.x * p1.y);
  }

  HCoordinate.of3(Coordinate p1, Coordinate p2) {
    x = p1.y - p2.y;
    y = p2.x - p1.x;
    w = (p1.x * p2.y) - (p2.x * p1.y);
  }

  HCoordinate.of4(Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    double px = p1.y - p2.y;
    double py = p2.x - p1.x;
    double pw = (p1.x * p2.y) - (p2.x * p1.y);
    double qx = q1.y - q2.y;
    double qy = q2.x - q1.x;
    double qw = (q1.x * q2.y) - (q2.x * q1.y);
    x = (py * qw) - (qy * pw);
    y = (qx * pw) - (px * qw);
    w = (px * qy) - (qx * py);
  }

  double getX() {
    double a = x / w;
    if (Double.isNaN(a) || Double.isInfinite(a)) {
      throw "NotRepresentableException";
    }
    return a;
  }

  double getY() {
    double a = y / w;
    if (Double.isNaN(a) || Double.isInfinite(a)) {
      throw "NotRepresentableException";
    }
    return a;
  }

  Coordinate getCoordinate() {
    Coordinate p = Coordinate();
    p.x = getX();
    p.y = getY();
    return p;
  }
}
