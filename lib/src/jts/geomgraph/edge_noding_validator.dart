import 'package:dts/src/jts/noding/basic_segment_string.dart';
import 'package:dts/src/jts/noding/fast_noding_validator.dart';

import 'edge.dart';

class EdgeNodingValidator {
  static void checkValid2(List<Edge> edges) {
    EdgeNodingValidator validator = EdgeNodingValidator(edges);
    validator.checkValid();
  }

  static List<BasicSegmentString> toSegmentStrings(List<Edge> edges) {
    List<BasicSegmentString> segStrings = [];
    for (var e in edges) {
      segStrings.add(BasicSegmentString(e.getCoordinates(), e));
    }
    return segStrings;
  }

  late FastNodingValidator _nv;

  EdgeNodingValidator(List<Edge> edges) {
    _nv = FastNodingValidator(toSegmentStrings(edges));
  }

  void checkValid() {
    _nv.checkValid();
  }


}
