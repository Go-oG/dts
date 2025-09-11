import 'package:dts/src/jts/geom/coordinate.dart';

import 'constraint_split_point_finder.dart';
import 'segment.dart';

final class MidpointSplitPointFinder implements ConstraintSplitPointFinder {
  @override
  Coordinate findSplitPoint(Segment seg, Coordinate encroachPt) {
    Coordinate p0 = seg.getStart();
    Coordinate p1 = seg.getEnd();
    return Coordinate((p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
  }
}
