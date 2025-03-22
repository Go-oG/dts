import 'package:dts/src/jts/geom/coordinate.dart';

class Octant {
  static int octant(double dx, double dy) {
    if ((dx == 0.0) && (dy == 0.0)) {
      throw ("Cannot compute the octant for point ($dx,$dy)");
    }

    double adx = dx.abs();
    double ady = dy.abs();
    if (dx >= 0) {
      if (dy >= 0) {
        if (adx >= ady) {
          return 0;
        } else {
          return 1;
        }
      } else if (adx >= ady) {
        return 7;
      } else {
        return 6;
      }
    } else if (dy >= 0) {
      if (adx >= ady) {
        return 3;
      } else {
        return 2;
      }
    } else if (adx >= ady) {
      return 4;
    } else {
      return 5;
    }
  }

  static int octant2(Coordinate p0, Coordinate p1) {
    double dx = p1.x - p0.x;
    double dy = p1.y - p0.y;
    if ((dx == 0.0) && (dy == 0.0)) {
      throw ("Cannot compute the octant for two identical points $p0");
    }

    return octant(dx, dy);
  }

  Octant();
}
