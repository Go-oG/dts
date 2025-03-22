 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';

import 'area.dart';
import 'cgalgorithms.dart';

class Orientation {
  Orientation._();

  static const int clockwise = -1;
  static const int right = clockwise;
  static const int counterClockwise = 1;
  static const int left = counterClockwise;
  static const int collinear = 0;
  static const int straight = collinear;

  static int index(Coordinate p1, Coordinate p2, Coordinate q) {
    return CGAlgorithmsDD.orientationIndex(p1, p2, q);
  }

  static bool isCCW(Array<Coordinate> ring) {
    return isCCW2(CoordinateArraySequence.of2(ring, 2, 0));
  }

  static bool isCCW2(CoordinateSequence ring) {
    int nPts = ring.size() - 1;
    if (nPts < 3) {
      return false;
    }

    Coordinate upHiPt = ring.getCoordinate(0);
    double prevY = upHiPt.y;
    Coordinate? upLowPt;
    int iUpHi = 0;
    for (int i = 1; i <= nPts; i++) {
      double py = ring.getOrdinate(i, Coordinate.Y);
      if ((py > prevY) && (py >= upHiPt.y)) {
        upHiPt = ring.getCoordinate(i);
        iUpHi = i;
        upLowPt = ring.getCoordinate(i - 1);
      }
      prevY = py;
    }
    if (iUpHi == 0) {
      return false;
    }

    int iDownLow = iUpHi;
    do {
      iDownLow = (iDownLow + 1) % nPts;
    } while ((iDownLow != iUpHi) && (ring.getOrdinate(iDownLow, Coordinate.Y) == upHiPt.y));
    Coordinate downLowPt = ring.getCoordinate(iDownLow);
    int iDownHi = (iDownLow > 0) ? iDownLow - 1 : nPts - 1;
    Coordinate downHiPt = ring.getCoordinate(iDownHi);
    if (upHiPt.equals2D(downHiPt)) {
      if ((upLowPt!.equals2D(upHiPt) || downLowPt.equals2D(upHiPt)) || upLowPt.equals2D(downLowPt)) {
        return false;
      }

      int indexV = index(upLowPt, upHiPt, downLowPt);
      return indexV == counterClockwise;
    } else {
      double delX = downHiPt.x - upHiPt.x;
      return delX < 0;
    }
  }

  static bool isCCWArea(Array<Coordinate> ring) {
    return Area.ofRingSigned(ring) < 0;
  }
}
