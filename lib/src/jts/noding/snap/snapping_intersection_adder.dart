import 'package:dts/src/jts/algorithm/distance.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/noding/noded_segment_string.dart';
import 'package:dts/src/jts/noding/segment_intersector.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'snapping_point_index.dart';

class SnappingIntersectionAdder implements NSegmentIntersector {
  LineIntersector li = RobustLineIntersector();

  final double _snapTolerance;

  final SnappingPointIndex _snapPointIndex;

  SnappingIntersectionAdder(this._snapTolerance, this._snapPointIndex);

  @override
  void processIntersections(
    covariant NodedSegmentString seg0,
    int segIndex0,
    covariant NodedSegmentString seg1,
    int segIndex1,
  ) {
    if ((seg0 == seg1) && (segIndex0 == segIndex1)) return;

    Coordinate p00 = seg0.getCoordinate(segIndex0);
    Coordinate p01 = seg0.getCoordinate(segIndex0 + 1);
    Coordinate p10 = seg1.getCoordinate(segIndex1);
    Coordinate p11 = seg1.getCoordinate(segIndex1 + 1);
    if (!isAdjacent(seg0, segIndex0, seg1, segIndex1)) {
      li.computeIntersection2(p00, p01, p10, p11);
      if (li.hasIntersection() && (li.getIntersectionNum() == 1)) {
        Coordinate intPt = li.getIntersection(0);
        Coordinate snapPt = _snapPointIndex.snap(intPt);
        seg0.addIntersection(snapPt, segIndex0);
        seg1.addIntersection(snapPt, segIndex1);
      }
    }
    processNearVertex(seg0, segIndex0, p00, seg1, segIndex1, p10, p11);
    processNearVertex(seg0, segIndex0, p01, seg1, segIndex1, p10, p11);
    processNearVertex(seg1, segIndex1, p10, seg0, segIndex0, p00, p01);
    processNearVertex(seg1, segIndex1, p11, seg0, segIndex0, p00, p01);
  }

  void processNearVertex(
    SegmentString srcSS,
    int srcIndex,
    Coordinate p,
    SegmentString ss,
    int segIndex,
    Coordinate p0,
    Coordinate p1,
  ) {
    if (p.distance(p0) < _snapTolerance) return;

    if (p.distance(p1) < _snapTolerance) return;

    double distSeg = Distance.pointToSegment(p, p0, p1);
    if (distSeg < _snapTolerance) {
      (ss as NodedSegmentString).addIntersection(p, segIndex);
      (srcSS as NodedSegmentString).addIntersection(p, srcIndex);
    }
  }

  static bool isAdjacent(SegmentString ss0, int segIndex0, SegmentString ss1, int segIndex1) {
    if (ss0 != ss1) return false;

    bool isAdjacent = (segIndex0 - segIndex1).abs() == 1;
    if (isAdjacent) return true;

    if (ss0.isClosed()) {
      int maxSegIndex = ss0.size() - 1;
      if (((segIndex0 == 0) && (segIndex1 == maxSegIndex)) || ((segIndex1 == 0) && (segIndex0 == maxSegIndex))) {
        return true;
      }
    }
    return false;
  }

  @override
  bool isDone() {
    return false;
  }
}
