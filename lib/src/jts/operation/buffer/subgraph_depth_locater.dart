import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';

import 'buffer_subgraph.dart';

class SubgraphDepthLocater {
  final List<BufferSubgraph> _subGraphs;
  final LineSegment _seg = LineSegment.empty();

  SubgraphDepthLocater(this._subGraphs);

  int getDepth(Coordinate p) {
    List<DepthSegment> stabbedSegments = findStabbedSegments(p);
    if (stabbedSegments.isEmpty) return 0;

    DepthSegment ds = stabbedSegments.min;
    return ds._leftDepth;
  }

  List<DepthSegment> findStabbedSegments(Coordinate stabbingRayLeftPt) {
    List<DepthSegment> stabbedSegments = [];
    for (var bsg in _subGraphs) {
      Envelope env = bsg.getEnvelope();
      if ((stabbingRayLeftPt.y < env.minY) || (stabbingRayLeftPt.y > env.maxY)) {
        continue;
      }

      findStabbedSegments3(stabbingRayLeftPt, bsg.getDirectedEdges(), stabbedSegments);
    }
    return stabbedSegments;
  }

  void findStabbedSegments3(
      Coordinate stabbingRayLeftPt, List<DirectedEdge> dirEdges, List stabbedSegments) {
    for (var de in dirEdges) {
      if (!de.isForward) continue;

      findStabbedSegments2(stabbingRayLeftPt, de, stabbedSegments);
    }
  }

  void findStabbedSegments2(
      Coordinate stabbingRayLeftPt, DirectedEdge dirEdge, List stabbedSegments) {
    Array<Coordinate> pts = dirEdge.getEdge().getCoordinates();
    for (int i = 0; i < (pts.length - 1); i++) {
      _seg.p0 = pts[i];
      _seg.p1 = pts[i + 1];
      if (_seg.p0.y > _seg.p1.y) _seg.reverse();

      double maxx = Math.maxD(_seg.p0.x, _seg.p1.x);
      if (maxx < stabbingRayLeftPt.x) continue;

      if (_seg.isHorizontal()) continue;

      if ((stabbingRayLeftPt.y < _seg.p0.y) || (stabbingRayLeftPt.y > _seg.p1.y)) continue;

      if (Orientation.index(_seg.p0, _seg.p1, stabbingRayLeftPt) == Orientation.right) continue;

      int depth = dirEdge.getDepth(Position.left);
      if (_seg.p0 != pts[i]) depth = dirEdge.getDepth(Position.right);

      final ds = DepthSegment(_seg, depth);
      stabbedSegments.add(ds);
    }
  }
}

class DepthSegment implements Comparable<DepthSegment> {
  late LineSegment _upwardSeg;

  late int _leftDepth;

  DepthSegment(LineSegment seg, int depth) {
    _upwardSeg = LineSegment.of(seg);
    _leftDepth = depth;
  }

  bool isUpward() {
    return _upwardSeg.p0.y <= _upwardSeg.p1.y;
  }

  @override
  int compareTo(DepthSegment other) {
    if ((((_upwardSeg.minX() >= other._upwardSeg.maxX()) ||
                (_upwardSeg.maxX() <= other._upwardSeg.minX())) ||
            (_upwardSeg.minY() >= other._upwardSeg.maxY())) ||
        (_upwardSeg.maxY() <= other._upwardSeg.minY())) {
      return _upwardSeg.compareTo(other._upwardSeg);
    }
    int orientIndex = _upwardSeg.orientationIndex2(other._upwardSeg);
    if (orientIndex != 0) return orientIndex;

    orientIndex = (-1) * other._upwardSeg.orientationIndex2(_upwardSeg);
    if (orientIndex != 0) return orientIndex;

    return 0;
  }

  int oldCompareTo(DepthSegment other) {
    if (_upwardSeg.minX() > other._upwardSeg.maxX()) return 1;

    if (_upwardSeg.maxX() < other._upwardSeg.minX()) return -1;

    int orientIndex = _upwardSeg.orientationIndex2(other._upwardSeg);
    if (orientIndex != 0) return orientIndex;

    orientIndex = (-1) * other._upwardSeg.orientationIndex2(_upwardSeg);
    if (orientIndex != 0) return orientIndex;

    return _upwardSeg.compareTo(other._upwardSeg);
  }

  @override
  String toString() {
    return _upwardSeg.toString();
  }
}
