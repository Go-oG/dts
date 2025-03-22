import 'package:dts/src/jts/noding/segment_intersector.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'noder.dart';

abstract class SinglePassNoder implements Noder {
  NSegmentIntersector? segInt;

  SinglePassNoder();

  SinglePassNoder.of(NSegmentIntersector segInt) {
    setSegmentIntersector(segInt);
  }

  void setSegmentIntersector(NSegmentIntersector segInt) {
    this.segInt = segInt;
  }

  @override
  void computeNodes(List<SegmentString> segStrings);
}
