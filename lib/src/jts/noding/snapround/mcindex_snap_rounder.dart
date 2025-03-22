 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/noding/interior_intersection_finder_adder.dart';
import 'package:dts/src/jts/noding/mcindex_noder.dart';
import 'package:dts/src/jts/noding/noded_segment_string.dart';
import 'package:dts/src/jts/noding/noder.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'hot_pixel.dart';
import 'mcindex_point_snapper.dart';

@deprecated
class MCIndexSnapRounder implements Noder {
  final PrecisionModel _pm;

  late LineIntersector li;

  late final double _scaleFactor;

  late MCIndexNoder _noder;

  late MCIndexPointSnapper _pointSnapper;

  late List<NodedSegmentString> _nodedSegStrings;

  MCIndexSnapRounder(this._pm) {
    li = RobustLineIntersector();
    li.setPrecisionModel(_pm);
    _scaleFactor = _pm.getScale();
  }

  @override
  List<SegmentString> getNodedSubstrings() {
    return NodedSegmentString.getNodedSubstrings(_nodedSegStrings);
  }

  @override
  void computeNodes(covariant List<NodedSegmentString> inputSegmentStrings) {
    _nodedSegStrings = inputSegmentStrings;
    _noder = MCIndexNoder();
    _pointSnapper = MCIndexPointSnapper(_noder.getIndex());
    snapRound(inputSegmentStrings, li);
  }

  void snapRound(List<NodedSegmentString> segStrings, LineIntersector li) {
    final intersections = findInteriorIntersections(segStrings, li);
    computeIntersectionSnaps(intersections);
    computeVertexSnaps(segStrings);
  }

  List<Coordinate> findInteriorIntersections(List<NodedSegmentString> segStrings, LineIntersector li) {
    final intFinderAdder = InteriorIntersectionFinderAdder(li);
    _noder.setSegmentIntersector(intFinderAdder);
    _noder.computeNodes(segStrings);
    return intFinderAdder.getInteriorIntersections();
  }

  void computeIntersectionSnaps(List<Coordinate> snapPts) {
    for (var snapPt in snapPts) {
      final hotPixel = HotPixel(snapPt, _scaleFactor);
      _pointSnapper.snap(hotPixel);
    }
  }

  void computeVertexSnaps(List<NodedSegmentString> edges) {
    for (var i0 in edges) {
      computeVertexSnaps2(i0);
    }
  }

  void computeVertexSnaps2(NodedSegmentString e) {
    Array<Coordinate> pts0 = e.getCoordinates();
    for (int i = 0; i < pts0.length; i++) {
      HotPixel hotPixel = HotPixel(pts0[i], _scaleFactor);
      bool isNodeAdded = _pointSnapper.snap2(hotPixel, e, i);
      if (isNodeAdded) {
        e.addIntersection(pts0[i], i);
      }
    }
  }
}
