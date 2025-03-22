 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

import 'noded_segment_string.dart';
import 'segment_intersector.dart';
import 'segment_string.dart';

class IntersectionAdder implements NSegmentIntersector {
  static bool isAdjacentSegments(int i1, int i2) {
    return Math.abs(i1 - i2) == 1;
  }

  Coordinate? properIntersectionPoint;

  bool hasProper = false;

  bool hasProperInterior = false;

  bool _hasInterior = false;

  LineIntersector li;

  bool isSelfIntersection = false;

  int numIntersections = 0;

  int numInteriorIntersections = 0;

  int numProperIntersections = 0;

  int numTests = 0;

  IntersectionAdder(this.li);

  bool hasIntersection = false;

  LineIntersector getLineIntersector() {
    return li;
  }

  bool hasProperIntersection() {
    return hasProper;
  }

  bool hasProperInteriorIntersection() {
    return hasProperInterior;
  }

  bool hasInteriorIntersection() {
    return _hasInterior;
  }

  bool isTrivialIntersection(SegmentString e0, int segIndex0, SegmentString e1, int segIndex1) {
    if (e0 == e1) {
      if (li.getIntersectionNum() == 1) {
        if (isAdjacentSegments(segIndex0, segIndex1)) return true;

        if (e0.isClosed()) {
          int maxSegIndex = e0.size() - 1;
          if (((segIndex0 == 0) && (segIndex1 == maxSegIndex)) || ((segIndex1 == 0) && (segIndex0 == maxSegIndex))) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void processIntersections(
    covariant NodedSegmentString e0,
    int segIndex0,
    covariant NodedSegmentString e1,
    int segIndex1,
  ) {
    if ((e0 == e1) && (segIndex0 == segIndex1)) return;

    numTests++;
    Coordinate p00 = e0.getCoordinate(segIndex0);
    Coordinate p01 = e0.getCoordinate(segIndex0 + 1);
    Coordinate p10 = e1.getCoordinate(segIndex1);
    Coordinate p11 = e1.getCoordinate(segIndex1 + 1);
    li.computeIntersection2(p00, p01, p10, p11);
    if (li.hasIntersection()) {
      numIntersections++;
      if (li.isInteriorIntersection()) {
        numInteriorIntersections++;
        _hasInterior = true;
      }
      if (!isTrivialIntersection(e0, segIndex0, e1, segIndex1)) {
        hasIntersection = true;
        e0.addIntersections(li, segIndex0, 0);
        e1.addIntersections(li, segIndex1, 1);
        if (li.isProper) {
          numProperIntersections++;
          hasProper = true;
          hasProperInterior = true;
        }
      }
    }
  }

  @override
  bool isDone() {
    return false;
  }
}
