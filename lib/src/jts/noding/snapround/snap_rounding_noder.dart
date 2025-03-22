 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/index/kd_tree.dart';
import 'package:dts/src/jts/noding/mcindex_noder.dart';
import 'package:dts/src/jts/noding/noded_segment_string.dart';
import 'package:dts/src/jts/noding/noder.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'hot_pixel.dart';
import 'hot_pixel_index.dart';
import 'snap_rounding_intersection_adder.dart';

class SnapRoundingNoder implements Noder {
  static const int _NEARNESS_FACTOR = 100;

  final PrecisionModel pm;

  late final HotPixelIndex _pixelIndex;

  List<NodedSegmentString>? _snappedResult;

  SnapRoundingNoder(this.pm) {
    _pixelIndex = HotPixelIndex(pm);
  }

  @override
  List<SegmentString> getNodedSubstrings() {
    return NodedSegmentString.getNodedSubstrings(_snappedResult!);
  }

  @override
  void computeNodes(covariant List<NodedSegmentString> inputSegmentStrings) {
    _snappedResult = snapRound(inputSegmentStrings);
  }

  List<NodedSegmentString> snapRound(List<NodedSegmentString> segStrings) {
    addIntersectionPixels(segStrings);
    addVertexPixels(segStrings);
    List<NodedSegmentString> snapped = computeSnaps(segStrings);
    return snapped;
  }

  void addIntersectionPixels(List<NodedSegmentString> segStrings) {
    double snapGridSize = 1.0 / pm.getScale();
    double nearnessTol = snapGridSize / _NEARNESS_FACTOR;
    final intAdder = SnapRoundingIntersectionAdder(nearnessTol);
    final noder = MCIndexNoder.of2(intAdder, nearnessTol);
    noder.computeNodes(segStrings);
    List<Coordinate> intPts = intAdder.getIntersections();
    _pixelIndex.addNodes(intPts);
  }

  void addVertexPixels(List<NodedSegmentString> segStrings) {
    for (SegmentString nss in segStrings) {
      Array<Coordinate> pts = nss.getCoordinates();
      _pixelIndex.add2(pts);
    }
  }

  Coordinate round(Coordinate pt) {
    Coordinate p2 = pt.copy();
    pm.makePrecise(p2);
    return p2;
  }

  Array<Coordinate> round2(Array<Coordinate> pts) {
    CoordinateList roundPts = CoordinateList();
    for (int i = 0; i < pts.length; i++) {
      roundPts.add3(round(pts[i]), false);
    }
    return roundPts.toCoordinateArray();
  }

  List<NodedSegmentString> computeSnaps(List<NodedSegmentString> segStrings) {
    List<NodedSegmentString> snapped = [];
    for (NodedSegmentString ss in segStrings) {
      final snappedSS = computeSegmentSnaps(ss);
      if (snappedSS != null) snapped.add(snappedSS);
    }
    for (NodedSegmentString ss in snapped) {
      addVertexNodeSnaps(ss);
    }
    return snapped;
  }

  NodedSegmentString? computeSegmentSnaps(NodedSegmentString ss) {
    Array<Coordinate> pts = ss.getNodedCoordinates();
    Array<Coordinate> ptsRound = round2(pts);
    if (ptsRound.length <= 1) return null;

    NodedSegmentString snapSS = NodedSegmentString(ptsRound, ss.getData());
    int snapSSindex = 0;
    for (int i = 0; i < (pts.length - 1); i++) {
      Coordinate currSnap = snapSS.getCoordinate(snapSSindex);
      Coordinate p1 = pts[i + 1];
      Coordinate p1Round = round(p1);
      if (p1Round.equals2D(currSnap)) continue;

      Coordinate p0 = pts[i];
      snapSegment(p0, p1, snapSS, snapSSindex);
      snapSSindex++;
    }
    return snapSS;
  }

  void snapSegment(Coordinate p0, Coordinate p1, NodedSegmentString ss, int segIndex) {
    _pixelIndex.query(
      p0,
      p1,
      KdNodeVisitor2((node) {
        HotPixel hp = node.getData() as HotPixel;
        if (!hp.isNode()) {
          if (hp.intersects(p0) || hp.intersects(p1)) {
            return;
          }
        }
        if (hp.intersects2(p0, p1)) {
          ss.addIntersection(hp.getCoordinate(), segIndex);
          hp.setToNode();
        }
      }),
    );
  }

  void addVertexNodeSnaps(NodedSegmentString ss) {
    Array<Coordinate> pts = ss.getCoordinates();
    for (int i = 1; i < (pts.length - 1); i++) {
      Coordinate p0 = pts[i];
      snapVertexNode(p0, ss, i);
    }
  }

  void snapVertexNode(Coordinate p0, NodedSegmentString ss, int segIndex) {
    _pixelIndex.query(
      p0,
      p0,
      KdNodeVisitor2((node) {
        HotPixel hp = node.getData() as HotPixel;
        if (hp.isNode() && hp.getCoordinate().equals2D(p0)) {
          ss.addIntersection(p0, segIndex);
        }
      }),
    );
  }
}
