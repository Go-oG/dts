import 'package:dts/src/jts/noding/segment_intersector.dart';

import 'segment_string.dart';

abstract interface class SegmentSetMutualIntersector {
  void process(List<SegmentString> segStrings, NSegmentIntersector segInt);
}
