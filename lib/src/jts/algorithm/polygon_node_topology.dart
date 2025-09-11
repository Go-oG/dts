import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/quadrant.dart';

import 'orientation.dart';

final class PolygonNodeTopology {
  PolygonNodeTopology._();

  static bool isCrossing(Coordinate nodePt, Coordinate a0, Coordinate a1,
      Coordinate b0, Coordinate b1) {
    Coordinate aLo = a0;
    Coordinate aHi = a1;
    if (_isAngleGreater(nodePt, aLo, aHi)) {
      aLo = a1;
      aHi = a0;
    }
    int compBetween0 = _compareBetween(nodePt, b0, aLo, aHi);
    if (compBetween0 == 0) {
      return false;
    }

    int compBetween1 = _compareBetween(nodePt, b1, aLo, aHi);
    if (compBetween1 == 0) {
      return false;
    }

    return compBetween0 != compBetween1;
  }

  static bool isInteriorSegment(
      Coordinate nodePt, Coordinate a0, Coordinate a1, Coordinate b) {
    Coordinate aLo = a0;
    Coordinate aHi = a1;
    bool isInteriorBetween = true;
    if (_isAngleGreater(nodePt, aLo, aHi)) {
      aLo = a1;
      aHi = a0;
      isInteriorBetween = false;
    }
    bool isBetween = _isBetween(nodePt, b, aLo, aHi);
    bool isInterior = (isBetween && isInteriorBetween) ||
        ((!isBetween) && (!isInteriorBetween));
    return isInterior;
  }

  static bool _isBetween(
      Coordinate origin, Coordinate p, Coordinate e0, Coordinate e1) {
    bool isGreater0 = _isAngleGreater(origin, p, e0);
    if (!isGreater0) {
      return false;
    }

    bool isGreater1 = _isAngleGreater(origin, p, e1);
    return !isGreater1;
  }

  static int _compareBetween(
      Coordinate origin, Coordinate p, Coordinate e0, Coordinate e1) {
    int comp0 = compareAngle(origin, p, e0);
    if (comp0 == 0) {
      return 0;
    }

    int comp1 = compareAngle(origin, p, e1);
    if (comp1 == 0) {
      return 0;
    }

    if ((comp0 > 0) && (comp1 < 0)) {
      return 1;
    }

    return -1;
  }

  static bool _isAngleGreater(Coordinate origin, Coordinate p, Coordinate q) {
    int quadrantP = _quadrant(origin, p);
    int quadrantQ = _quadrant(origin, q);
    if (quadrantP > quadrantQ) {
      return true;
    }

    if (quadrantP < quadrantQ) {
      return false;
    }

    int orient = Orientation.index(origin, q, p);
    return orient == Orientation.counterClockwise;
  }

  static int compareAngle(Coordinate origin, Coordinate p, Coordinate q) {
    int quadrantP = _quadrant(origin, p);
    int quadrantQ = _quadrant(origin, q);
    if (quadrantP > quadrantQ) {
      return 1;
    }

    if (quadrantP < quadrantQ) {
      return -1;
    }

    int orient = Orientation.index(origin, q, p);
    switch (orient) {
      case Orientation.counterClockwise:
        return 1;
      case Orientation.clockwise:
        return -1;
      default:
        return 0;
    }
  }

  static int _quadrant(Coordinate origin, Coordinate p) {
    double dx = p.x - origin.x;
    double dy = p.y - origin.y;
    return Quadrant.quadrant(dx, dy);
  }
}
