import 'package:dts/src/jts/algorithm/polygon_node_topology.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/noding/segment_intersector.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'coverage_ring.dart';

class InvalidSegmentDetector implements NSegmentIntersector {
  double _distanceTol = 0;

  InvalidSegmentDetector([double distanceTol = 0]) {
    _distanceTol = distanceTol;
  }

  @override
  void processIntersections(
      SegmentString ssAdj, int iAdj, SegmentString ssTarget, int iTarget) {
    CoverageRing target = ((ssTarget) as CoverageRing);
    CoverageRing adj = ((ssAdj as CoverageRing));
    if (target.isKnown2(iTarget)) {
      return;
    }

    Coordinate t0 = target.getCoordinate(iTarget);
    Coordinate t1 = target.getCoordinate(iTarget + 1);
    Coordinate adj0 = adj.getCoordinate(iAdj);
    Coordinate adj1 = adj.getCoordinate(iAdj + 1);
    if (t0.equals2D(t1) || adj0.equals2D(adj1)) {
      return;
    }

    if (_isEqual(t0, t1, adj0, adj1)) {
      return;
    }

    bool isInvalid = _isInvalid(t0, t1, adj0, adj1, adj, iAdj);
    if (isInvalid) {
      target.markInvalid(iTarget);
    }
  }

  bool _isEqual(
      Coordinate t0, Coordinate t1, Coordinate adj0, Coordinate adj1) {
    if (t0.equals2D(adj0) && t1.equals2D(adj1)) {
      return true;
    }

    if (t0.equals2D(adj1) && t1.equals2D(adj0)) {
      return true;
    }

    return false;
  }

  bool _isInvalid(Coordinate tgt0, Coordinate tgt1, Coordinate adj0,
      Coordinate adj1, CoverageRing adj, int indexAdj) {
    if (_isCollinearOrInterior(tgt0, tgt1, adj0, adj1, adj, indexAdj)) {
      return true;
    }

    if ((_distanceTol > 0) &&
        _isNearlyParallel(tgt0, tgt1, adj0, adj1, _distanceTol)) {
      return true;
    }

    return false;
  }

  bool _isCollinearOrInterior(
    Coordinate tgt0,
    Coordinate tgt1,
    Coordinate adj0,
    Coordinate adj1,
    CoverageRing adj,
    int indexAdj,
  ) {
    RobustLineIntersector li = RobustLineIntersector();
    li.computeIntersection2(tgt0, tgt1, adj0, adj1);
    if (!li.hasIntersection()) {
      return false;
    }

    if (li.getIntersectionNum() == 2) {
      return true;
    }
    if (li.isProper || li.isInteriorIntersection()) {
      return true;
    }
    Coordinate intVertex = li.getIntersection(0);
    bool isInterior = _isInteriorSegment(intVertex, tgt0, tgt1, adj, indexAdj);
    return isInterior;
  }

  bool _isInteriorSegment(Coordinate intVertex, Coordinate tgt0,
      Coordinate tgt1, CoverageRing adj, int indexAdj) {
    Coordinate tgtEnd = (intVertex.equals2D(tgt0)) ? tgt1 : tgt0;
    Coordinate adjPrev = adj.findVertexPrev(indexAdj, intVertex);
    Coordinate adjNext = adj.findVertexNext(indexAdj, intVertex);
    if (tgtEnd.equals2D(adjPrev) || tgtEnd.equals2D(adjNext)) {
      return false;
    }
    if (!adj.isInteriorOnRight()) {
      Coordinate temp = adjPrev;
      adjPrev = adjNext;
      adjNext = temp;
    }
    bool isInterior = PolygonNodeTopology.isInteriorSegment(
        intVertex, adjPrev, adjNext, tgtEnd);
    return isInterior;
  }

  static bool _isNearlyParallel(Coordinate p00, Coordinate p01, Coordinate p10,
      Coordinate p11, double distanceTol) {
    LineSegment line0 = LineSegment(p00, p01);
    LineSegment line1 = LineSegment(p10, p11);
    LineSegment proj0 = line0.project3(line1)!;
    LineSegment proj1 = line1.project3(line0)!;

    if ((proj0.getLength() <= distanceTol) ||
        (proj1.getLength() <= distanceTol)) {
      return false;
    }

    if (proj0.p0.distance(proj1.p1) < proj0.p0.distance(proj1.p0)) {
      proj1.reverse();
    }
    return (proj0.p0.distance(proj1.p0) <= distanceTol) &&
        (proj0.p1.distance(proj1.p1) <= distanceTol);
  }

  @override
  bool isDone() {
    return false;
  }
}
