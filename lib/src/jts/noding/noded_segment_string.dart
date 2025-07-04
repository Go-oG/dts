import 'package:d_util/d_util.dart';

import '../algorithm/line_intersector.dart';
import '../geom/coordinate.dart';
import 'nodable_segment_string.dart';
import 'octant.dart';
import 'segment_node.dart';
import 'segment_node_list.dart';
import 'segment_string.dart';

class NodedSegmentString extends NodableSegmentString {
  static List<SegmentString> getNodedSubstrings(List<NodedSegmentString> segStrings) {
    List<SegmentString> resultEdgelist = [];
    getNodedSubstrings2(segStrings, resultEdgelist);
    return resultEdgelist;
  }

  static void getNodedSubstrings2(
      List<NodedSegmentString> segStrings, List<SegmentString> resultEdgelist) {
    for (var segString in segStrings) {
      segString.getNodeList().addSplitEdges(resultEdgelist);
    }
  }

  late final SegmentNodeList _nodeList = SegmentNodeList(this);

  Array<Coordinate> pts;

  Object? data;

  NodedSegmentString(this.pts, this.data);

  NodedSegmentString.of(SegmentString ss) : this(ss.getCoordinates(), ss.getData());

  @override
  Object? getData() {
    return data;
  }

  @override
  void setData(Object? data) {
    this.data = data;
  }

  SegmentNodeList getNodeList() {
    return _nodeList;
  }

  @override
  int size() {
    return pts.length;
  }

  @override
  Coordinate getCoordinate(int i) {
    return pts[i];
  }

  @override
  Array<Coordinate> getCoordinates() {
    return pts;
  }

  Array<Coordinate> getNodedCoordinates() {
    return _nodeList.getSplitCoordinates();
  }

  @override
  bool isClosed() {
    return pts[0] == pts[pts.length - 1];
  }

  bool hasNodes() {
    return _nodeList.size() > 0;
  }

  int getSegmentOctant(int index) {
    if (index == (pts.length - 1)) return -1;

    return safeOctant(getCoordinate(index), getCoordinate(index + 1));
  }

  int safeOctant(Coordinate p0, Coordinate p1) {
    if (p0.equals2D(p1)) return 0;

    return Octant.octant2(p0, p1);
  }

  void addIntersections(LineIntersector li, int segmentIndex, int geomIndex) {
    for (int i = 0; i < li.getIntersectionNum(); i++) {
      addIntersection2(li, segmentIndex, geomIndex, i);
    }
  }

  @override
  void addIntersection(Coordinate intPt, int segmentIndex) {
    addIntersectionNode(intPt, segmentIndex);
  }

  void addIntersection2(LineIntersector li, int segmentIndex, int geomIndex, int intIndex) {
    Coordinate intPt = li.getIntersection(intIndex).copy();
    addIntersection(intPt, segmentIndex);
  }

  SegmentNode addIntersectionNode(Coordinate intPt, int segmentIndex) {
    int normalizedSegmentIndex = segmentIndex;
    int nextSegIndex = normalizedSegmentIndex + 1;
    if (nextSegIndex < pts.length) {
      Coordinate nextPt = pts[nextSegIndex];
      if (intPt.equals2D(nextPt)) {
        normalizedSegmentIndex = nextSegIndex;
      }
    }
    return _nodeList.add(intPt, normalizedSegmentIndex);
  }
}
