import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/noding/segment_intersector.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'relate_segment_string.dart';
import 'topology_computer.dart';

class EdgeSegmentIntersector implements NSegmentIntersector {
  final _li = RobustLineIntersector();

  final TopologyComputer topoComputer;

  EdgeSegmentIntersector(this.topoComputer);

  @override
  bool isDone() {
    return topoComputer.isResultKnown();
  }

  @override
  void processIntersections(SegmentString ss0, int segIndex0, SegmentString ss1, int segIndex1) {
    if ((ss0 == ss1) && (segIndex0 == segIndex1)) return;

    RelateSegmentString rss0 = ss0 as RelateSegmentString;
    RelateSegmentString rss1 = ss1 as RelateSegmentString;
    if (rss0.isA) {
      addIntersections(rss0, segIndex0, rss1, segIndex1);
    } else {
      addIntersections(rss1, segIndex1, rss0, segIndex0);
        }
    }

     void addIntersections(RelateSegmentString ssA, int segIndexA, RelateSegmentString ssB, int segIndexB) {
        Coordinate a0 = ssA.getCoordinate(segIndexA);
        Coordinate a1 = ssA.getCoordinate(segIndexA + 1);
        Coordinate b0 = ssB.getCoordinate(segIndexB);
        Coordinate b1 = ssB.getCoordinate(segIndexB + 1);
    _li.computeIntersection2(a0, a1, b0, b1);
    if (!_li.hasIntersection()) {
      return;
    }

    for (int i = 0; i < _li.getIntersectionNum(); i++) {
            Coordinate intPt = _li.getIntersection(i);
      if (_li.isProper || (ssA.isContainingSegment(segIndexA, intPt) && ssB.isContainingSegment(segIndexB, intPt))) {
        final nsa = ssA.createNodeSection(segIndexA, intPt);
        final nsb = ssB.createNodeSection(segIndexB, intPt);
        topoComputer.addIntersection(nsa, nsb);
      }
    }
    }
}
