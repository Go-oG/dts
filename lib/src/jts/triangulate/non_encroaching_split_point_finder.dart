import 'package:dts/src/jts/geom/coordinate.dart';

import 'constraint_split_point_finder.dart';
import 'segment.dart';
import 'split_segment.dart';

class NonEncroachingSplitPointFinder implements ConstraintSplitPointFinder {
  @override
  Coordinate findSplitPoint(Segment seg, Coordinate encroachPt) {
    final lineSeg = seg.getLineSegment();
    double segLen = lineSeg.getLength();
    double midPtLen = segLen / 2;
    final splitSeg = SplitSegment(lineSeg);
    final projPt = projectedSplitPoint(seg, encroachPt);
    double nonEncroachDiam = (projPt.distance(encroachPt) * 2) * 0.8;
    double maxSplitLen = nonEncroachDiam;
    if (maxSplitLen > midPtLen) {
      maxSplitLen = midPtLen;
    }
    splitSeg.setMinimumLength(maxSplitLen);
    splitSeg.splitAt2(projPt);
    return splitSeg.getSplitPoint();
  }

  static Coordinate projectedSplitPoint(Segment seg, Coordinate encroachPt) {
    final lineSeg = seg.getLineSegment();
    return lineSeg.project(encroachPt);
  }
}
