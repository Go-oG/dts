 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

import 'segment_intersector.dart';
import 'segment_string.dart';

class SegmentIntersectionDetector implements NSegmentIntersector {
  late LineIntersector li;

  bool _findProper = false;

  bool _findAllTypes = false;

  bool hasIntersection = false;

  bool hasProperIntersection = false;

  bool hasNonProperIntersection = false;

  Coordinate? _intPt;

  Array<Coordinate>? intSegments;

  SegmentIntersectionDetector([LineIntersector? li]) {
    this.li = li ?? RobustLineIntersector();
  }

  void setFindProper(bool findProper) {
    _findProper = findProper;
  }

  void setFindAllIntersectionTypes(bool findAllTypes) {
    _findAllTypes = findAllTypes;
  }

  Coordinate? getIntersection() {
    return _intPt;
  }

  Array<Coordinate>? getIntersectionSegments() {
    return intSegments;
  }

  @override
  void processIntersections(SegmentString e0, int segIndex0, SegmentString e1, int segIndex1) {
    if ((e0 == e1) && (segIndex0 == segIndex1)) return;

    Coordinate p00 = e0.getCoordinate(segIndex0);
    Coordinate p01 = e0.getCoordinate(segIndex0 + 1);
    Coordinate p10 = e1.getCoordinate(segIndex1);
    Coordinate p11 = e1.getCoordinate(segIndex1 + 1);
    li.computeIntersection2(p00, p01, p10, p11);
    if (li.hasIntersection()) {
      hasIntersection = true;
      bool isProper = li.isProper;
      if (isProper) hasProperIntersection = true;

      if (!isProper) hasNonProperIntersection = true;

      bool saveLocation = true;
      if (_findProper && (!isProper)) saveLocation = false;

      if ((_intPt == null) || saveLocation) {
        _intPt = li.getIntersection(0);
        intSegments = Array(4);
        intSegments![0] = p00;
        intSegments![1] = p01;
        intSegments![2] = p10;
        intSegments![3] = p11;
      }
    }
  }

  @override
  bool isDone() {
    if (_findAllTypes) {
      return hasProperIntersection && hasNonProperIntersection;
    }
    if (_findProper) {
      return hasProperIntersection;
    }
    return hasIntersection;
  }
}
