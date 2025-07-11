 import 'package:d_util/d_util.dart';

import '../../algorithm/line_intersector.dart';
import '../../algorithm/robust_line_intersector.dart';
import '../../geom/coordinate.dart';
import '../../noding/mcindex_noder.dart';
import '../../noding/noded_segment_string.dart';
import '../../noding/segment_intersector.dart';
import '../../noding/segment_string.dart';

class PolygonNoder {
  late Array<bool> _isHoleTouching;

  late List<NodedSegmentString> _nodedRings;

  PolygonNoder(Array<Coordinate> shellRing, Array<Array<Coordinate>> holeRings) {
    _nodedRings = createNodedSegmentStrings(shellRing, holeRings);
    _isHoleTouching = Array(holeRings.length);
  }

  void node() {
    NSegmentIntersector nodeAdder = NodeAdder(_isHoleTouching);
    MCIndexNoder noder = MCIndexNoder.of(nodeAdder);
    noder.computeNodes(_nodedRings);
  }

  bool isShellNoded() {
    return _nodedRings.get(0).hasNodes();
  }

  bool isHoleNoded(int i) {
    return _nodedRings.get(i + 1).hasNodes();
  }

  Array<Coordinate> getNodedShell() {
    return _nodedRings.get(0).getNodedCoordinates();
  }

  Array<Coordinate> getNodedHole(int i) {
    return _nodedRings.get(i + 1).getNodedCoordinates();
  }

  Array<bool> getHolesTouching() {
    return _isHoleTouching;
  }

  static List<NodedSegmentString> createNodedSegmentStrings(
    Array<Coordinate> shellRing,
    Array<Array<Coordinate>> holeRings,
  ) {
    List<NodedSegmentString> segStr = [];
    segStr.add(createNodedSegString(shellRing, -1));
    for (int i = 0; i < holeRings.length; i++) {
      segStr.add(createNodedSegString(holeRings[i], i));
    }
    return segStr;
  }

  static NodedSegmentString createNodedSegString(Array<Coordinate> ringPts, int i) {
    return NodedSegmentString(ringPts, i);
  }
}

class NodeAdder extends NSegmentIntersector {
  LineIntersector li = RobustLineIntersector();

  Array<bool> isHoleTouching;

  NodeAdder(this.isHoleTouching);

  @override
  void processIntersections(SegmentString ss0, int segIndex0, SegmentString ss1, int segIndex1) {
    if (ss0 == ss1) return;

    Coordinate p00 = ss0.getCoordinate(segIndex0);
    Coordinate p01 = ss0.getCoordinate(segIndex0 + 1);
    Coordinate p10 = ss1.getCoordinate(segIndex1);
    Coordinate p11 = ss1.getCoordinate(segIndex1 + 1);
    li.computeIntersection2(p00, p01, p10, p11);
    if (li.getIntersectionNum() == 1) {
      addTouch(ss0);
      addTouch(ss1);
      Coordinate intPt = li.getIntersection(0);
      if (li.isInteriorIntersection2(0)) {
        (ss0 as NodedSegmentString).addIntersectionNode(intPt, segIndex0);
      } else if (li.isInteriorIntersection2(1)) {
        (ss1 as NodedSegmentString).addIntersectionNode(intPt, segIndex1);
      }
    }
  }

  void addTouch(SegmentString ss) {
    int holeIndex = ss.getData() as int;
    if (holeIndex >= 0) {
      isHoleTouching[holeIndex] = true;
    }
  }

  @override
  bool isDone() {
    return false;
  }
}
