 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/algorithm/point_location.dart';
import 'package:dts/src/jts/algorithm/polygon_node_topology.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/noding/basic_segment_string.dart';
import 'package:dts/src/jts/noding/mcindex_noder.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'polygon_intersection_analyzer.dart';
import 'polygon_ring.dart';

class PolygonTopologyAnalyzer {
  static bool isRingNested(LinearRing test, LinearRing target) {
    Coordinate p0 = test.getCoordinateN(0);
    Array<Coordinate> targetPts = target.getCoordinates();
    int loc = PointLocation.locateInRing(p0, targetPts);
    if (loc == Location.exterior) {
      return false;
    }

    if (loc == Location.interior) {
      return true;
    }

    Coordinate p1 = findNonEqualVertex(test, p0);
    return isIncidentSegmentInRing(p0, p1, targetPts);
  }

  static Coordinate findNonEqualVertex(LinearRing ring, Coordinate p) {
    int i = 1;
    Coordinate next = ring.getCoordinateN(i);
    while (next.equals2D(p) && (i < (ring.getNumPoints() - 1))) {
      i += 1;
      next = ring.getCoordinateN(i);
    }
    return next;
  }

  static bool isIncidentSegmentInRing(Coordinate p0, Coordinate p1, Array<Coordinate> ringPts) {
    int index = intersectingSegIndex(ringPts, p0);
    if (index < 0) {
      throw IllegalArgumentException("Segment vertex does not intersect ring");
    }
    Coordinate rPrev = findRingVertexPrev(ringPts, index, p0);
    Coordinate rNext = findRingVertexNext(ringPts, index, p0);
    bool isInteriorOnRight = !Orientation.isCCW(ringPts);
    if (!isInteriorOnRight) {
      Coordinate temp = rPrev;
      rPrev = rNext;
      rNext = temp;
    }
    return PolygonNodeTopology.isInteriorSegment(p0, rPrev, rNext, p1);
  }

  static Coordinate findRingVertexPrev(Array<Coordinate> ringPts, int index, Coordinate node) {
    int iPrev = index;
    Coordinate prev = ringPts[iPrev];
    while (node.equals2D(prev)) {
      iPrev = ringIndexPrev(ringPts, iPrev);
      prev = ringPts[iPrev];
    }
    return prev;
  }

  static Coordinate findRingVertexNext(Array<Coordinate> ringPts, int index, Coordinate node) {
    int iNext = index + 1;
    Coordinate next = ringPts[iNext];
    while (node.equals2D(next)) {
      iNext = ringIndexNext(ringPts, iNext);
      next = ringPts[iNext];
    }
    return next;
  }

  static int ringIndexPrev(Array<Coordinate> ringPts, int index) {
    if (index == 0) {
      return ringPts.length - 2;
    }

    return index - 1;
  }

  static int ringIndexNext(Array<Coordinate> ringPts, int index) {
    if (index >= (ringPts.length - 2)) {
      return 0;
    }

    return index + 1;
  }

  static int intersectingSegIndex(Array<Coordinate> ringPts, Coordinate pt) {
    for (int i = 0; i < (ringPts.length - 1); i++) {
      if (PointLocation.isOnSegment(pt, ringPts[i], ringPts[i + 1])) {
        if (pt.equals2D(ringPts[i + 1])) {
          return i + 1;
        }
        return i;
      }
    }
    return -1;
  }

  static Coordinate? findSelfIntersection(LinearRing ring) {
    PolygonTopologyAnalyzer ata = PolygonTopologyAnalyzer(ring, false);
    if (ata.hasInvalidIntersection()) {
      return ata.getInvalidLocation();
    }

    return null;
  }

  bool isInvertedRingValid;

  late PolygonIntersectionAnalyzer _intFinder;

  List<PolygonRing>? _polyRings;

  Coordinate? _disconnectionPt;

  PolygonTopologyAnalyzer(Geometry geom, this.isInvertedRingValid) {
    analyze(geom);
  }

  bool hasInvalidIntersection() {
    return _intFinder.isInvalid();
  }

  int getInvalidCode() {
    return _intFinder.getInvalidCode();
  }

  Coordinate? getInvalidLocation() {
    return _intFinder.getInvalidLocation();
  }

  bool isInteriorDisconnected() {
    if (_disconnectionPt != null) {
      return true;
    }
    if (isInvertedRingValid) {
      checkInteriorDisconnectedBySelfTouch();
      if (_disconnectionPt != null) {
        return true;
      }
    }
    checkInteriorDisconnectedByHoleCycle();
    if (_disconnectionPt != null) {
      return true;
    }
    return false;
  }

  Coordinate? getDisconnectionLocation() {
    return _disconnectionPt;
  }

  void checkInteriorDisconnectedByHoleCycle() {
    if (_polyRings != null) {
      _disconnectionPt = PolygonRing.findHoleCycleLocationS(_polyRings!);
    }
  }

  void checkInteriorDisconnectedBySelfTouch() {
    if (_polyRings != null) {
      _disconnectionPt = PolygonRing.findInteriorSelfNodeS(_polyRings!);
    }
  }

  void analyze(Geometry geom) {
    if (geom.isEmpty()) {
      return;
    }

    List<SegmentString> segStrings = createSegmentStrings(geom, isInvertedRingValid);
    _polyRings = getPolygonRings(segStrings);
    _intFinder = analyzeIntersections(segStrings);
    if (_intFinder.hasDoubleTouch()) {
      _disconnectionPt = _intFinder.getDoubleTouchLocation();
      return;
    }
  }

  PolygonIntersectionAnalyzer analyzeIntersections(List<SegmentString> segStrings) {
    PolygonIntersectionAnalyzer segInt = PolygonIntersectionAnalyzer(isInvertedRingValid);
    MCIndexNoder noder = MCIndexNoder();
    noder.setSegmentIntersector(segInt);
    noder.computeNodes(segStrings);
    return segInt;
  }

  static List<SegmentString> createSegmentStrings(Geometry geom, bool isInvertedRingValid) {
    List<SegmentString> segStrings = [];
    if (geom is LinearRing) {
      segStrings.add(createSegString(geom, null));
      return segStrings;
    }
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Polygon poly = (geom.getGeometryN(i) as Polygon);
      if (poly.isEmpty()) {
        continue;
      }

      bool hasHoles = poly.getNumInteriorRing() > 0;
      PolygonRing? shellRing;
      if (hasHoles || isInvertedRingValid) {
        shellRing = PolygonRing(poly.getExteriorRing());
      }
      segStrings.add(createSegString(poly.getExteriorRing(), shellRing));
      for (int j = 0; j < poly.getNumInteriorRing(); j++) {
        LinearRing hole = poly.getInteriorRingN(j);
        if (hole.isEmpty()) {
          continue;
        }

        PolygonRing holeRing = PolygonRing(hole, j, shellRing);
        segStrings.add(createSegString(hole, holeRing));
      }
    }
    return segStrings;
  }

  static List<PolygonRing> getPolygonRings(List<SegmentString> segStrings) {
    List<PolygonRing>? polyRings = [];
    for (SegmentString ss in segStrings) {
      PolygonRing? polyRing = (ss.getData() as PolygonRing?);
      if (polyRing != null) {
        polyRings.add(polyRing);
      }
    }
    return polyRings;
  }

  static SegmentString createSegString(LinearRing ring, PolygonRing? polyRing) {
    Array<Coordinate> pts = ring.getCoordinates();
    if (CoordinateArrays.hasRepeatedPoints(pts)) {
      pts = CoordinateArrays.removeRepeatedPoints(pts);
    }
    SegmentString ss = BasicSegmentString(pts, polyRing);
    return ss;
  }
}
