 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

import 'segment_intersector.dart';
import 'segment_set_mutual_intersector.dart';
import 'segment_string.dart';

class SimpleSegmentSetMutualIntersector implements SegmentSetMutualIntersector {
  final List _baseSegStrings;

  SimpleSegmentSetMutualIntersector(this._baseSegStrings);

  @override
  void process(List<SegmentString> segStrings, NSegmentIntersector segInt) {
    for (var baseSS in _baseSegStrings) {
      for (var ss in segStrings) {
        intersect(baseSS, ss, segInt);
        if (segInt.isDone()) {
          return;
        }
      }
    }
  }

  void intersect(SegmentString ss0, SegmentString ss1, NSegmentIntersector segInt) {
    Array<Coordinate> pts0 = ss0.getCoordinates();
    Array<Coordinate> pts1 = ss1.getCoordinates();
    for (int i0 = 0; i0 < (pts0.length - 1); i0++) {
      for (int i1 = 0; i1 < (pts1.length - 1); i1++) {
        segInt.processIntersections(ss0, i0, ss1, i1);
        if (segInt.isDone()) return;
      }
    }
  }
}
