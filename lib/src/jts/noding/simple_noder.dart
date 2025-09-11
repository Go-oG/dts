import 'noded_segment_string.dart';
import 'segment_string.dart';
import 'single_pass_noder.dart';

class SimpleNoder extends SinglePassNoder {
  late List<SegmentString> nodedSegStrings;

  @override
  List<SegmentString> getNodedSubstrings() {
    return NodedSegmentString.getNodedSubstrings(nodedSegStrings.cast());
  }

  @override
  void computeNodes(List<SegmentString> inputSegStrings) {
    nodedSegStrings = inputSegStrings;
    for (var edge0 in inputSegStrings) {
      for (var edge1 in inputSegStrings) {
        computeIntersects(edge0, edge1);
      }
    }
  }

  void computeIntersects(SegmentString e0, SegmentString e1) {
    final pts0 = e0.getCoordinates();
    final pts1 = e1.getCoordinates();
    for (int i0 = 0; i0 < (pts0.length - 1); i0++) {
      for (int i1 = 0; i1 < (pts1.length - 1); i1++) {
        segInt!.processIntersections(e0, i0, e1, i1);
      }
    }
  }
}
