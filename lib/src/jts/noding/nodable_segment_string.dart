import 'package:dts/src/jts/geom/coordinate.dart';
import 'segment_string.dart';

abstract class NodableSegmentString extends SegmentString {
  void addIntersection(Coordinate intPt, int segmentIndex);
}
