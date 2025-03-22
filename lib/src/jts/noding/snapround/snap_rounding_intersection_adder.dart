import 'package:dts/src/jts/algorithm/distance.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/noding/noded_segment_string.dart';
import 'package:dts/src/jts/noding/segment_intersector.dart';



class SnapRoundingIntersectionAdder implements NSegmentIntersector {
  final LineIntersector _li = RobustLineIntersector();

  final List<Coordinate> _intersections = [];

  final double _nearnessTol;

  SnapRoundingIntersectionAdder(this._nearnessTol);

  List<Coordinate> getIntersections() {
    return _intersections;
  }

  @override
  void processIntersections(
    covariant NodedSegmentString e0,
    int segIndex0,
    covariant NodedSegmentString e1,
    int segIndex1,
  ) {
    if ((e0 == e1) && (segIndex0 == segIndex1)) return;

    Coordinate p00 = e0.getCoordinate(segIndex0);
    Coordinate p01 = e0.getCoordinate(segIndex0 + 1);
    Coordinate p10 = e1.getCoordinate(segIndex1);
    Coordinate p11 = e1.getCoordinate(segIndex1 + 1);
    _li.computeIntersection2(p00, p01, p10, p11);
    if (_li.hasIntersection()) {
      if (_li.isInteriorIntersection()) {
        for (int intIndex = 0; intIndex < _li.getIntersectionNum(); intIndex++) {
          _intersections.add(_li.getIntersection(intIndex));
        }
        e0.addIntersections(_li, segIndex0, 0);
        e1.addIntersections(_li, segIndex1, 1);
        return;
      }
    }
    processNearVertex(p00, e1, segIndex1, p10, p11);
    processNearVertex(p01, e1, segIndex1, p10, p11);
    processNearVertex(p10, e0, segIndex0, p00, p01);
    processNearVertex(p11, e0, segIndex0, p00, p01);
  }

  void processNearVertex(Coordinate p, NodedSegmentString edge, int segIndex, Coordinate p0, Coordinate p1) {
    if (p.distance(p0) < _nearnessTol) return;

    if (p.distance(p1) < _nearnessTol) return;

    double distSeg = Distance.pointToSegment(p, p0, p1);
    if (distSeg < _nearnessTol) {
      _intersections.add(p);
      edge.addIntersection(p, segIndex);
    }
  }

  @override
  bool isDone() {
    return false;
  }
}
