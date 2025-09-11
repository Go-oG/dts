import 'segment_string.dart';

abstract class NSegmentIntersector {
  void processIntersections(
      SegmentString e0, int segIndex0, SegmentString e1, int segIndex1);

  bool isDone();
}
