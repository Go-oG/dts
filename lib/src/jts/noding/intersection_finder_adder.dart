import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'noded_segment_string.dart';
import 'segment_intersector.dart';

class IntersectionFinderAdder implements NSegmentIntersector {
  LineIntersector li;

  final List interiorIntersections = [];

  IntersectionFinderAdder(this.li);

  List getInteriorIntersections() {
    return interiorIntersections;
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
    li.computeIntersection2(p00, p01, p10, p11);
    if (li.hasIntersection()) {
      if (li.isInteriorIntersection()) {
        for (int intIndex = 0; intIndex < li.getIntersectionNum(); intIndex++) {
          interiorIntersections.add(li.getIntersection(intIndex));
        }
        e0.addIntersections(li, segIndex0, 0);
        e1.addIntersections(li, segIndex1, 1);
      }
    }
  }

  @override
  bool isDone() {
    return false;
  }
}
