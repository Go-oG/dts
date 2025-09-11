import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/math/math.dart';
import 'package:dts/src/jts/noding/mcindex_noder.dart';
import 'package:dts/src/jts/noding/noded_segment_string.dart';
import 'package:dts/src/jts/noding/noder.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'snapping_intersection_adder.dart';
import 'snapping_point_index.dart';

class SnappingNoder implements Noder {
  late final SnappingPointIndex _snapIndex;

  double snapTolerance;

  List<NodedSegmentString>? _nodedResult;

  SnappingNoder(this.snapTolerance) {
    _snapIndex = SnappingPointIndex(snapTolerance);
  }

  @override
  List<NodedSegmentString>? getNodedSubstrings() {
    return _nodedResult;
  }

  @override
  void computeNodes(List<SegmentString> inputSegStrings) {
    List<NodedSegmentString> snappedSS = snapVertices2(inputSegStrings);
    _nodedResult = snapIntersections(snappedSS);
  }

  List<NodedSegmentString> snapVertices2(List<SegmentString> segStrings) {
    seedSnapIndex(segStrings);
    List<NodedSegmentString> nodedStrings = [];
    for (SegmentString ss in segStrings) {
      nodedStrings.add(snapVertices(ss));
    }
    return nodedStrings;
  }

  void seedSnapIndex(List<SegmentString> segStrings) {
    final int seedSizeFactor = 100;
    for (SegmentString ss in segStrings) {
      final pts = ss.getCoordinates();
      int numPtsToLoad = pts.length ~/ seedSizeFactor;
      double rand = 0.0;
      for (int i = 0; i < numPtsToLoad; i++) {
        rand = MathUtil.quasirandom(rand);
        int index = (pts.length * rand).toInt();
        _snapIndex.snap(pts[index]);
      }
    }
  }

  NodedSegmentString snapVertices(SegmentString ss) =>
      NodedSegmentString(snap(ss.getCoordinates()), ss.getData());

  List<Coordinate> snap(List<Coordinate> coords) {
    CoordinateList snapCoords = CoordinateList();
    for (int i = 0; i < coords.length; i++) {
      Coordinate pt = _snapIndex.snap(coords[i]);
      snapCoords.add3(pt, false);
    }
    return snapCoords.toCoordinateList();
  }

  List<NodedSegmentString> snapIntersections(List<NodedSegmentString> inputSS) {
    final intAdder = SnappingIntersectionAdder(snapTolerance, _snapIndex);
    final noder = MCIndexNoder.of2(intAdder, 2 * snapTolerance);
    noder.computeNodes(inputSS);
    return noder.getNodedSubstrings().cast();
  }
}
