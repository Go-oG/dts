 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'basic_segment_string.dart';
import 'noder.dart';

class SegmentExtractingNoder implements Noder {
  List<SegmentString>? _segList;

  @override
  void computeNodes(List<SegmentString> segStrings) {
    _segList = extractSegments(segStrings);
  }

  static List<SegmentString> extractSegments(List<SegmentString> segStrings) {
    List<SegmentString> segList = [];
    for (SegmentString ss in segStrings) {
      extractSegments2(ss, segList);
    }
    return segList;
  }

  static void extractSegments2(SegmentString ss, List<SegmentString> segList) {
    for (int i = 0; i < (ss.size() - 1); i++) {
      Coordinate p0 = ss.getCoordinate(i);
      Coordinate p1 = ss.getCoordinate(i + 1);
      SegmentString seg = BasicSegmentString([p0, p1].toArray(), ss.getData());
      segList.add(seg);
    }
  }

  @override
  List<SegmentString>? getNodedSubstrings() {
    return _segList;
  }
}
