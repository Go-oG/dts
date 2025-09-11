import 'mcindex_segment_set_mutual_intersector.dart';
import 'segment_intersection_detector.dart';
import 'segment_set_mutual_intersector.dart';
import 'segment_string.dart';

class FastSegmentSetIntersectionFinder {
  late final SegmentSetMutualIntersector _segSetMutInt;

  FastSegmentSetIntersectionFinder(List<SegmentString> baseSegStrings) {
    _segSetMutInt = MCIndexSegmentSetMutualIntersector(baseSegStrings);
  }

  SegmentSetMutualIntersector getSegmentSetIntersector() {
    return _segSetMutInt;
  }

  bool intersects(List<SegmentString> segStrings) {
    final intFinder = SegmentIntersectionDetector();
    return intersects2(segStrings, intFinder);
  }

  bool intersects2(
      List<SegmentString> segStrings, SegmentIntersectionDetector intDetector) {
    _segSetMutInt.process(segStrings, intDetector);
    return intDetector.hasIntersection;
  }
}
