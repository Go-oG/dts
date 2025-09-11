import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

import 'segment_intersector.dart';
import 'segment_string.dart';

class NodingIntersectionFinder implements NSegmentIntersector {
  static NodingIntersectionFinder createAnyIntersectionFinder(
      LineIntersector li) {
    return NodingIntersectionFinder(li);
  }

  static NodingIntersectionFinder createAllIntersectionsFinder(
      LineIntersector li) {
    NodingIntersectionFinder finder = NodingIntersectionFinder(li);
    finder.setFindAllIntersections(true);
    return finder;
  }

  static NodingIntersectionFinder createInteriorIntersectionsFinder(
      LineIntersector li) {
    NodingIntersectionFinder finder = NodingIntersectionFinder(li);
    finder.setFindAllIntersections(true);
    finder.setInteriorIntersectionsOnly(true);
    return finder;
  }

  static NodingIntersectionFinder createIntersectionCounter(
      LineIntersector li) {
    NodingIntersectionFinder finder = NodingIntersectionFinder(li);
    finder.setFindAllIntersections(true);
    finder.setKeepIntersections(false);
    return finder;
  }

  static NodingIntersectionFinder createInteriorIntersectionCounter(
      LineIntersector li) {
    NodingIntersectionFinder finder = NodingIntersectionFinder(li);
    finder.setInteriorIntersectionsOnly(true);
    finder.setFindAllIntersections(true);
    finder.setKeepIntersections(false);
    return finder;
  }

  bool findAllIntersections = false;

  bool _isCheckEndSegmentsOnly = false;

  bool _keepIntersections = true;

  bool _isInteriorIntersectionsOnly = false;

  LineIntersector li;

  Coordinate? _interiorIntersection;

  Array<Coordinate>? _intSegments;

  final List<Coordinate> _intersections = [];

  int _intersectionCount = 0;

  NodingIntersectionFinder(this.li) {
    _interiorIntersection = null;
  }

  void setFindAllIntersections(bool findAllIntersections) {
    this.findAllIntersections = findAllIntersections;
  }

  void setInteriorIntersectionsOnly(bool isInteriorIntersectionsOnly) {
    _isInteriorIntersectionsOnly = isInteriorIntersectionsOnly;
  }

  void setCheckEndSegmentsOnly(bool isCheckEndSegmentsOnly) {
    _isCheckEndSegmentsOnly = isCheckEndSegmentsOnly;
  }

  void setKeepIntersections(bool keepIntersections) {
    _keepIntersections = keepIntersections;
  }

  List<Coordinate> getIntersections() {
    return _intersections;
  }

  int count() {
    return _intersectionCount;
  }

  bool hasIntersection() {
    return _interiorIntersection != null;
  }

  Coordinate? getIntersection() {
    return _interiorIntersection;
  }

  Array<Coordinate>? getIntersectionSegments() {
    return _intSegments;
  }

  @override
  void processIntersections(
      SegmentString e0, int segIndex0, SegmentString e1, int segIndex1) {
    if ((!findAllIntersections) && hasIntersection()) return;

    bool isSameSegString = e0 == e1;
    bool isSameSegment = isSameSegString && (segIndex0 == segIndex1);
    if (isSameSegment) return;

    if (_isCheckEndSegmentsOnly) {
      bool isEndSegPresent =
          isEndSegment(e0, segIndex0) || isEndSegment(e1, segIndex1);
      if (!isEndSegPresent) return;
    }
    Coordinate p00 = e0.getCoordinate(segIndex0);
    Coordinate p01 = e0.getCoordinate(segIndex0 + 1);
    Coordinate p10 = e1.getCoordinate(segIndex1);
    Coordinate p11 = e1.getCoordinate(segIndex1 + 1);
    bool isEnd00 = segIndex0 == 0;
    bool isEnd01 = (segIndex0 + 2) == e0.size();
    bool isEnd10 = segIndex1 == 0;
    bool isEnd11 = (segIndex1 + 2) == e1.size();
    li.computeIntersection2(p00, p01, p10, p11);
    bool isInteriorInt = li.hasIntersection() && li.isInteriorIntersection();
    bool isInteriorVertexInt = false;
    if (!_isInteriorIntersectionsOnly) {
      bool isAdjacentSegment =
          isSameSegString && (Math.abs(segIndex1 - segIndex0) <= 1);
      isInteriorVertexInt = (!isAdjacentSegment) &&
          _isInteriorVertexIntersection(
              p00, p01, p10, p11, isEnd00, isEnd01, isEnd10, isEnd11);
    }
    if (isInteriorInt || isInteriorVertexInt) {
      _intSegments = Array(4);
      _intSegments![0] = p00;
      _intSegments![1] = p01;
      _intSegments![2] = p10;
      _intSegments![3] = p11;
      _interiorIntersection = li.getIntersection(0);
      if (_keepIntersections) _intersections.add(_interiorIntersection!);

      _intersectionCount++;
    }
  }

  static bool _isInteriorVertexIntersection(
    Coordinate p00,
    Coordinate p01,
    Coordinate p10,
    Coordinate p11,
    bool isEnd00,
    bool isEnd01,
    bool isEnd10,
    bool isEnd11,
  ) {
    if (_isInteriorVertexIntersection2(p00, p10, isEnd00, isEnd10)) return true;

    if (_isInteriorVertexIntersection2(p00, p11, isEnd00, isEnd11)) return true;

    if (_isInteriorVertexIntersection2(p01, p10, isEnd01, isEnd10)) return true;

    if (_isInteriorVertexIntersection2(p01, p11, isEnd01, isEnd11)) return true;

    return false;
  }

  static bool _isInteriorVertexIntersection2(
      Coordinate p0, Coordinate p1, bool isEnd0, bool isEnd1) {
    if (isEnd0 && isEnd1) return false;

    if (p0.equals2D(p1)) {
      return true;
    }
    return false;
  }

  static bool isEndSegment(SegmentString segStr, int index) {
    if (index == 0) return true;

    if (index >= (segStr.size() - 2)) return true;

    return false;
  }

  @override
  bool isDone() {
    if (findAllIntersections) return false;

    return _interiorIntersection != null;
  }
}
