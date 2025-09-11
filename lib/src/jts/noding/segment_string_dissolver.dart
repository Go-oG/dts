import 'dart:collection';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';

import 'oriented_coordinate_array.dart';
import 'segment_string.dart';

class SegmentStringDissolver {
  final SegmentStringMerger? _merger;

  Map<OrientedCoordinateArray, SegmentString> ocaMap = SplayTreeMap();

  SegmentStringDissolver([this._merger]);

  void dissolve(List<SegmentString> segStrings) {
    for (var i in segStrings) {
      dissolve2(i);
    }
  }

  void add(OrientedCoordinateArray oca, SegmentString segString) {
    ocaMap.put(oca, segString);
  }

  void dissolve2(SegmentString segString) {
    OrientedCoordinateArray oca =
        OrientedCoordinateArray(segString.getCoordinates());
    SegmentString? existing = findMatching(oca, segString);
    if (existing == null) {
      add(oca, segString);
    } else if (_merger != null) {
      bool isSameOrientation = CoordinateArrays.equals(
          existing.getCoordinates(), segString.getCoordinates());
      _merger!.merge(existing, segString, isSameOrientation);
    }
  }

  SegmentString? findMatching(
      OrientedCoordinateArray oca, SegmentString segString) {
    return ocaMap.get(oca);
  }

  List<SegmentString> getDissolved() {
    return ocaMap.values.toList();
  }
}

abstract interface class SegmentStringMerger {
  void merge(SegmentString mergeTarget, SegmentString ssToMerge,
      bool isSameOrientation);
}
