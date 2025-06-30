import 'dart:collection';
import 'dart:core';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/algorithm/polygon_node_topology.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/noding/basic_segment_string.dart';
import 'package:dts/src/jts/noding/mcindex_segment_set_mutual_intersector.dart';
import 'package:dts/src/jts/noding/segment_intersector.dart';
import 'package:dts/src/jts/noding/segment_set_mutual_intersector.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'polygon_noder.dart';

class PolygonHoleJoiner {
  static Polygon joinAsPolygon(Polygon polygon) {
    return polygon.factory.createPolygon3(join(polygon));
  }

  static Array<Coordinate> join(Polygon polygon) {
    PolygonHoleJoiner joiner = PolygonHoleJoiner(polygon);
    return joiner.compute();
  }

  late final Polygon _inputPolygon;

  late Array<Coordinate> _shellRing;

  late Array<Array<Coordinate>> _holeRings;

  late Array<bool> _isHoleTouchingHint;

  late List<Coordinate> _joinedRing;

  late SplayTreeSet<Coordinate> _joinedPts;

  late SegmentSetMutualIntersector _boundaryIntersector;

  PolygonHoleJoiner(this._inputPolygon);

  Array<Coordinate> compute() {
    extractOrientedRings(_inputPolygon);
    if (_holeRings.length > 0) {
      nodeRings();
    }

    _joinedRing = copyToList(_shellRing);
    if (_holeRings.length > 0) {
      joinHoles();
    }

    return CoordinateArrays.toCoordinateArray(_joinedRing);
  }

  void extractOrientedRings(Polygon polygon) {
    _shellRing = extractOrientedRing(polygon.getExteriorRing(), true);
    List<LinearRing> holes = sortHoles(polygon);
    _holeRings = Array(holes.size);
    for (int i = 0; i < holes.size; i++) {
      _holeRings[i] = extractOrientedRing(holes.get(i), false);
    }
  }

  static Array<Coordinate> extractOrientedRing(LinearRing ring, bool isCW) {
    Array<Coordinate> pts = ring.getCoordinates();
    bool isRingCW = !Orientation.isCCW(pts);
    if (isCW == isRingCW) {
      return pts;
    }

    Array<Coordinate> ptsRev = pts.copy();
    CoordinateArrays.reverse(ptsRev);
    return ptsRev;
  }

  void nodeRings() {
    PolygonNoder noder = PolygonNoder(_shellRing, _holeRings);
    noder.node();
    if (noder.isShellNoded()) {
      _shellRing = noder.getNodedShell();
    }
    for (int i = 0; i < _holeRings.length; i++) {
      if (noder.isHoleNoded(i)) {
        _holeRings[i] = noder.getNodedHole(i);
      }
    }
    _isHoleTouchingHint = noder.getHolesTouching();
  }

  static List<Coordinate> copyToList(Array<Coordinate> coords) {
    List<Coordinate> coordList = <Coordinate>[];
    for (var p in coords) {
      coordList.add((p).copy());
    }
    return coordList;
  }

  void joinHoles() {
    _boundaryIntersector = createBoundaryIntersector(_shellRing, _holeRings);
    _joinedPts = SplayTreeSet<Coordinate>();
    _joinedPts.addAll(_joinedRing);
    for (int i = 0; i < _holeRings.length; i++) {
      joinHole(i, _holeRings[i]);
    }
  }

  void joinHole(int index, Array<Coordinate> holeCoords) {
    if (_isHoleTouchingHint[index]) {
      bool isTouching = joinTouchingHole(holeCoords);
      if (isTouching) return;
    }
    joinNonTouchingHole(holeCoords);
  }

  bool joinTouchingHole(Array<Coordinate> holeCoords) {
    int holeTouchIndex = findHoleTouchIndex(holeCoords);
    if (holeTouchIndex < 0) return false;

    Coordinate joinPt = holeCoords[holeTouchIndex];
    Coordinate holeSegPt = holeCoords[prev(holeTouchIndex, holeCoords.length)];
    int joinIndex = findJoinIndex(joinPt, holeSegPt);
    addJoinedHole(joinIndex, holeCoords, holeTouchIndex);
    return true;
  }

  int findHoleTouchIndex(Array<Coordinate> holeCoords) {
    for (int i = 0; i < holeCoords.length; i++) {
      if (_joinedPts.contains(holeCoords[i])) {
        return i;
      }
    }
    return -1;
  }

  void joinNonTouchingHole(Array<Coordinate> holeCoords) {
    int holeJoinIndex = findLowestLeftVertexIndex(holeCoords);
    Coordinate holeJoinCoord = holeCoords[holeJoinIndex];
    Coordinate joinCoord = findJoinableVertex(holeJoinCoord);
    int joinIndex = findJoinIndex(joinCoord, holeJoinCoord);
    addJoinedHole(joinIndex, holeCoords, holeJoinIndex);
  }

  Coordinate findJoinableVertex(Coordinate holeJoinCoord) {
    Coordinate? candidate = _joinedPts.higher(holeJoinCoord);
    while (candidate!.x == holeJoinCoord.x) {
      candidate = _joinedPts.higher(candidate);
    }
    candidate = _joinedPts.lower(candidate);
    while (intersectsBoundary(holeJoinCoord, candidate!)) {
      candidate = _joinedPts.lower(candidate);
      if (candidate == null) {
        throw ("Unable to find joinable vertex");
      }
    }
    return candidate;
  }

  int findJoinIndex(Coordinate joinCoord, Coordinate holeJoinCoord) {
    for (int i = 0; i < (_joinedRing.size - 1); i++) {
      if (joinCoord.equals2D(_joinedRing.get(i))) {
        if (isLineInterior(_joinedRing, i, holeJoinCoord)) {
          return i;
        }
      }
    }
    throw ("Unable to find shell join index with interior join line");
  }

  bool isLineInterior(List<Coordinate> ring, int ringIndex, Coordinate linePt) {
    Coordinate nodePt = ring.get(ringIndex);
    Coordinate shell0 = ring.get(prev(ringIndex, ring.size));
    Coordinate shell1 = ring.get(next(ringIndex, ring.size));
    return PolygonNodeTopology.isInteriorSegment(nodePt, shell0, shell1, linePt);
  }

  static int prev(int i, int size) {
    int prev = i - 1;
    if (prev < 0) {
      return size - 2;
    }

    return prev;
  }

  static int next(int i, int size) {
    int next = i + 1;
    if (next > (size - 2)) {
      return 0;
    }

    return next;
  }

  void addJoinedHole(int joinIndex, Array<Coordinate> holeCoords, int holeJoinIndex) {
    Coordinate joinPt = _joinedRing.get(joinIndex);
    Coordinate holeJoinPt = holeCoords[holeJoinIndex];
    bool isVertexTouch = joinPt.equals2D(holeJoinPt);
    Coordinate? addJoinPt = isVertexTouch ? null : joinPt;
    List<Coordinate> newSection = createHoleSection(holeCoords, holeJoinIndex, addJoinPt);
    int addIndex = joinIndex + 1;
    _joinedRing.insertAll(addIndex, newSection);
    _joinedPts.addAll(newSection);
  }

  List<Coordinate> createHoleSection(
      Array<Coordinate> holeCoords, int holeJoinIndex, Coordinate? joinPt) {
    List<Coordinate> section = <Coordinate>[];
    bool isNonTouchingHole = joinPt != null;
    if (isNonTouchingHole) {
      section.add(holeCoords[holeJoinIndex].copy());
    }

    final int holeSize = holeCoords.length - 1;
    int index = holeJoinIndex;
    for (int i = 0; i < holeSize; i++) {
      index = (index + 1) % holeSize;
      section.add(holeCoords[index].copy());
    }
    if (isNonTouchingHole) {
      section.add(joinPt.copy());
    }
    return section;
  }

  static List<LinearRing> sortHoles(final Polygon poly) {
    List<LinearRing> holes = [];
    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      holes.add(poly.getInteriorRingN(i));
    }
    holes.sort(EnvelopeComparator().compare);
    return holes;
  }

  static int findLowestLeftVertexIndex(Array<Coordinate> coords) {
    Coordinate? lowestLeftCoord;
    int lowestLeftIndex = -1;
    for (int i = 0; i < (coords.length - 1); i++) {
      if ((lowestLeftCoord == null) || (coords[i].compareTo(lowestLeftCoord) < 0)) {
        lowestLeftCoord = coords[i];
        lowestLeftIndex = i;
      }
    }
    return lowestLeftIndex;
  }

  bool intersectsBoundary(Coordinate p0, Coordinate p1) {
    SegmentString segString = BasicSegmentString([p0, p1].toArray(), null);
    List<SegmentString> segStrings = [];
    segStrings.add(segString);
    final segInt = InteriorIntersectionDetector();
    _boundaryIntersector.process(segStrings, segInt);
    return segInt.hasIntersection;
  }

  static SegmentSetMutualIntersector createBoundaryIntersector(
    Array<Coordinate> shellRing,
    Array<Array<Coordinate>> holeRings,
  ) {
    List<SegmentString> polySegStrings = [];
    polySegStrings.add(BasicSegmentString(shellRing, null));
    holeRings.each((hole, index) {
      polySegStrings.add(BasicSegmentString(hole, null));
    });
    return MCIndexSegmentSetMutualIntersector(polySegStrings);
  }
}

class EnvelopeComparator implements CComparator<LinearRing> {
  @override
  int compare(Geometry g1, Geometry g2) {
    Envelope e1 = g1.getEnvelopeInternal();
    Envelope e2 = g2.getEnvelopeInternal();
    return e1.compareTo(e2);
  }
}

class InteriorIntersectionDetector implements NSegmentIntersector {
  LineIntersector li = RobustLineIntersector();

  bool hasIntersection = false;

  @override
  void processIntersections(SegmentString ss0, int segIndex0, SegmentString ss1, int segIndex1) {
    Coordinate p00 = ss0.getCoordinate(segIndex0);
    Coordinate p01 = ss0.getCoordinate(segIndex0 + 1);
    Coordinate p10 = ss1.getCoordinate(segIndex1);
    Coordinate p11 = ss1.getCoordinate(segIndex1 + 1);
    li.computeIntersection2(p00, p01, p10, p11);
    if (li.getIntersectionNum() == 0) {
      return;
    } else if (li.getIntersectionNum() == 1) {
      if (li.isInteriorIntersection()) {
        hasIntersection = true;
      }
    } else {
      hasIntersection = true;
    }
  }

  @override
  bool isDone() {
    return hasIntersection;
  }
}
