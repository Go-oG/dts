import 'coordinate.dart';

class Quadrant {
  static const int NE = 0;

  static const int NW = 1;

  static const int SW = 2;

  static const int SE = 3;

  static int quadrant(double dx, double dy) {
    if ((dx == 0.0) && (dy == 0.0)) {
      throw ("Cannot compute the quadrant for point ( $dx, $dy");
    }

    if (dx >= 0.0) {
      if (dy >= 0.0) {
        return NE;
      } else {
        return SE;
      }
    } else if (dy >= 0.0) {
      return NW;
    } else {
      return SW;
    }
  }

  static int quadrant2(Coordinate p0, Coordinate p1) {
    if ((p1.x == p0.x) && (p1.y == p0.y)) {
      throw ("Cannot compute the quadrant for two identical points $p0");
    }

    if (p1.x >= p0.x) {
      if (p1.y >= p0.y) {
        return NE;
      } else {
        return SE;
      }
    } else if (p1.y >= p0.y)
      return NW;
    else
      return SW;
  }

  static bool isOpposite(int quad1, int quad2) {
    if (quad1 == quad2) return false;

    int diff = ((quad1 - quad2) + 4) % 4;
    if (diff == 2) return true;

    return false;
  }

  static int commonHalfPlane(int quad1, int quad2) {
    if (quad1 == quad2) return quad1;

    int diff = ((quad1 - quad2) + 4) % 4;
    if (diff == 2) return -1;

    int min = (quad1 < quad2) ? quad1 : quad2;
    int max = (quad1 > quad2) ? quad1 : quad2;
    if ((min == 0) && (max == 3)) return 3;

    return min;
  }

  static bool isInHalfPlane(int quad, int halfPlane) {
    if (halfPlane == SE) {
      return (quad == SE) || (quad == SW);
    }
    return (quad == halfPlane) || (quad == (halfPlane + 1));
  }

  static bool isNorthern(int quad) {
    return (quad == NE) || (quad == NW);
  }
}
