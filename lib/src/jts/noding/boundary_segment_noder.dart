 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

import 'basic_segment_string.dart';
import 'noder.dart';
import 'segment_string.dart';

class NBoundarySegmentNoder implements Noder {
  List<SegmentString>? _segList;

  @override
  void computeNodes(List<SegmentString> segStrings) {
    Set<_Segment> segSet = <_Segment>{};
    addSegments2(segStrings, segSet);
    _segList = extractSegments(segSet);
  }

  static void addSegments2(List<SegmentString> segStrings, Set<_Segment> segSet) {
    for (SegmentString ss in segStrings) {
      addSegments(ss, segSet);
    }
  }

  static void addSegments(SegmentString segString, Set<_Segment> segSet) {
    for (int i = 0; i < (segString.size() - 1); i++) {
      Coordinate p0 = segString.getCoordinate(i);
      Coordinate p1 = segString.getCoordinate(i + 1);
      _Segment seg = _Segment(p0, p1, segString, i);
      if (segSet.contains(seg)) {
        segSet.remove(seg);
      } else {
        segSet.add(seg);
      }
    }
  }

  static List<SegmentString> extractSegments(Set<_Segment> segSet) {
    List<SegmentString> segList = [];
    for (_Segment seg in segSet) {
      SegmentString ss = seg.getSegmentString();
      int i = seg.getIndex();
      Coordinate p0 = ss.getCoordinate(i);
      Coordinate p1 = ss.getCoordinate(i + 1);
      SegmentString segStr = BasicSegmentString([p0, p1].toArray(), ss.getData());
      segList.add(segStr);
    }
    return segList;
  }

  @override
  List<SegmentString>? getNodedSubstrings() {
    return _segList;
  }
}

class _Segment extends LineSegment {
  final SegmentString _segStr;

  int index;

  _Segment(super.p0, super.p1, this._segStr, this.index) {
    normalize();
  }

  SegmentString getSegmentString() {
    return _segStr;
  }

  int getIndex() {
    return index;
  }
}
