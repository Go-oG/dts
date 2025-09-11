import 'coordinate.dart';

class Quadrant {
  static const int kNe = 0;
  static const int kNw = 1;
  static const int kSw = 2;
  static const int kSe = 3;

  static int quadrant(double dx, double dy) {
    if ((dx == 0.0) && (dy == 0.0)) {
      throw ("Cannot compute the quadrant for point ( $dx, $dy");
    }

    if (dx >= 0.0) {
      if (dy >= 0.0) {
        return kNe;
      } else {
        return kSe;
      }
    } else if (dy >= 0.0) {
      return kNw;
    } else {
      return kSw;
    }
  }

  static int quadrant2(Coordinate p0, Coordinate p1) {
    if ((p1.x == p0.x) && (p1.y == p0.y)) {
      throw ("Cannot compute the quadrant for two identical points $p0");
    }

    if (p1.x >= p0.x) {
      if (p1.y >= p0.y) {
        return kNe;
      }
      return kSe;
    }
    if (p1.y >= p0.y) {
      return kNw;
    }
    return kSw;
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
    if (halfPlane == kSe) {
      return (quad == kSe) || (quad == kSw);
    }
    return (quad == halfPlane) || (quad == (halfPlane + 1));
  }

  static bool isNorthern(int quad) {
    return (quad == kNe) || (quad == kNw);
  }
}
