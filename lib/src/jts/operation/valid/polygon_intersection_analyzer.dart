import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/polygon_node_topology.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/noding/segment_intersector.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'polygon_ring.dart';
import 'topology_validation_error.dart';

class PolygonIntersectionAnalyzer implements NSegmentIntersector {
  static const int _noInvalidInterSection = -1;

  final bool _isInvertedRingValid;

  final LineIntersector li = RobustLineIntersector();

  int _invalidCode = _noInvalidInterSection;

  Coordinate? invalidLocation;

  bool _hasDoubleTouch = false;

  Coordinate? _doubleTouchLocation;

  PolygonIntersectionAnalyzer(this._isInvertedRingValid);

  @override
  bool isDone() {
    return isInvalid() || _hasDoubleTouch;
  }

  bool isInvalid() {
    return _invalidCode >= 0;
  }

  int getInvalidCode() {
    return _invalidCode;
  }

  Coordinate? getInvalidLocation() {
    return invalidLocation;
  }

  bool hasDoubleTouch() {
    return _hasDoubleTouch;
  }

  Coordinate? getDoubleTouchLocation() {
    return _doubleTouchLocation;
  }

  @override
  void processIntersections(SegmentString ss0, int segIndex0, SegmentString ss1, int segIndex1) {
    bool isSameSegString = ss0 == ss1;
    bool isSameSegment = isSameSegString && (segIndex0 == segIndex1);
    if (isSameSegment) return;

    int code = findInvalidIntersection(ss0, segIndex0, ss1, segIndex1);
    if (code != _noInvalidInterSection) {
      _invalidCode = code;
      invalidLocation = li.getIntersection(0);
    }
  }

  int findInvalidIntersection(SegmentString ss0, int segIndex0, SegmentString ss1, int segIndex1) {
    Coordinate p00 = ss0.getCoordinate(segIndex0);
    Coordinate p01 = ss0.getCoordinate(segIndex0 + 1);
    Coordinate p10 = ss1.getCoordinate(segIndex1);
    Coordinate p11 = ss1.getCoordinate(segIndex1 + 1);
    li.computeIntersection2(p00, p01, p10, p11);
    if (!li.hasIntersection()) {
      return _noInvalidInterSection;
    }
    bool isSameSegString = ss0 == ss1;
    if (li.isProper || (li.getIntersectionNum() >= 2)) {
      return TopologyValidationError.kSelfIntersection;
    }
    Coordinate intPt = li.getIntersection(0);
    bool isAdjacentSegments = isSameSegString && isAdjacentInRing(ss0, segIndex0, segIndex1);
    if (isAdjacentSegments) return _noInvalidInterSection;

    if (isSameSegString && (!_isInvertedRingValid)) {
      return TopologyValidationError.kRingSelfIntersection;
    }
    if (intPt.equals2D(p01) || intPt.equals2D(p11)) {
      return _noInvalidInterSection;
    }

    Coordinate e00 = p00;
    Coordinate e01 = p01;
    if (intPt.equals2D(p00)) {
      e00 = prevCoordinateInRing(ss0, segIndex0);
      e01 = p01;
    }
    Coordinate e10 = p10;
    Coordinate e11 = p11;
    if (intPt.equals2D(p10)) {
      e10 = prevCoordinateInRing(ss1, segIndex1);
      e11 = p11;
    }
    bool hasCrossing = PolygonNodeTopology.isCrossing(intPt, e00, e01, e10, e11);
    if (hasCrossing) {
      return TopologyValidationError.kSelfIntersection;
    }
    if (isSameSegString && _isInvertedRingValid) {
      addSelfTouch(ss0, intPt, e00, e01, e10, e11);
    }
    bool isDoubleTouch = addDoubleTouch(ss0, ss1, intPt);
    if (isDoubleTouch && (!isSameSegString)) {
      _hasDoubleTouch = true;
      _doubleTouchLocation = intPt;
    }
    return _noInvalidInterSection;
  }

  bool addDoubleTouch(SegmentString ss0, SegmentString ss1, Coordinate intPt) {
    return PolygonRing.addTouchS(ss0.getData() as PolygonRing, ss1.getData() as PolygonRing, intPt);
  }

  void addSelfTouch(
    SegmentString ss,
    Coordinate intPt,
    Coordinate e00,
    Coordinate e01,
    Coordinate e10,
    Coordinate e11,
  ) {
    PolygonRing? polyRing = ss.getData() as PolygonRing?;
    if (polyRing == null) {
      throw ("SegmentString missing PolygonRing data when checking self-touches");
    }
    polyRing.addSelfTouch(intPt, e00, e01, e10, e11);
  }

  static Coordinate prevCoordinateInRing(SegmentString ringSS, int segIndex) {
    int prevIndex = segIndex - 1;
    if (prevIndex < 0) {
      prevIndex = ringSS.size() - 2;
    }
    return ringSS.getCoordinate(prevIndex);
  }

  static bool isAdjacentInRing(SegmentString ringSS, int segIndex0, int segIndex1) {
    int delta = Math.abs(segIndex1 - segIndex0).toInt();
    if (delta <= 1) return true;

    if (delta >= (ringSS.size() - 2)) return true;

    return false;
  }
}
