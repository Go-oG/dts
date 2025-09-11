import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';

import 'segment_intersector.dart';

class SweepLineSegment {
  Edge edge;
  late List<Coordinate> pts;
  int ptIndex;
  SweepLineSegment(this.edge, this.ptIndex) {
    pts = edge.getCoordinates();
  }

  double getMinX() {
    double x1 = pts[ptIndex].x;
    double x2 = pts[ptIndex + 1].x;
    return x1 < x2 ? x1 : x2;
  }

  double getMaxX() {
    double x1 = pts[ptIndex].x;
    double x2 = pts[ptIndex + 1].x;
    return x1 > x2 ? x1 : x2;
  }

  void computeIntersections(SweepLineSegment ss, SegmentIntersector si) {
    si.addIntersections(edge, ptIndex, ss.edge, ss.ptIndex);
  }
}
