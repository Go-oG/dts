import 'package:dts/src/jts/geom/coordinate.dart';

import 'segment.dart';

abstract interface class ConstraintSplitPointFinder {
  Coordinate findSplitPoint(Segment seg, Coordinate encroachPt);
}
