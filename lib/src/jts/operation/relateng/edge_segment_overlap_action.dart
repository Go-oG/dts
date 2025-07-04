import 'package:dts/src/jts/index/monotone_chain.dart';
import 'package:dts/src/jts/noding/segment_intersector.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

class EdgeSegmentOverlapAction extends MonotoneChainOverlapAction {
  final NSegmentIntersector si;

  EdgeSegmentOverlapAction(this.si);

  @override
  void overlap2(MonotoneChain mc1, int start1, MonotoneChain mc2, int start2) {
    SegmentString ss1 = mc1.context as SegmentString;
    SegmentString ss2 = mc2.context as SegmentString;
    si.processIntersections(ss1, start1, ss2, start2);
  }
}
