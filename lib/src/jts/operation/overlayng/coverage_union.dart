import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/noding/boundary_chain_noder.dart';
import 'package:dts/src/jts/noding/noder.dart';
import 'package:dts/src/jts/noding/segment_extracting_noder.dart';

import 'overlay_ng.dart';

class CoverageUnionNG {
  static Geometry union(Geometry coverage) {
    Noder noder = NBoundaryChainNoder();
    if (coverage.getDimension() < 2) {
      noder = SegmentExtractingNoder();
    }
    return OverlayNG.union2(coverage, null, noder);
  }
}
