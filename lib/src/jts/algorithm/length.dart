import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/math/math.dart';

final class Length {
  Length._();

  static double ofLine(CoordinateSequence pts) {
    int n = pts.size();
    if (n <= 1) {
      return 0.0;
    }
    double len = 0.0;
    Coordinate p = pts.createCoordinate();
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
