import 'package:dts/src/jts/algorithm/distance.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

import 'geometry_location.dart';

class FacetSequence {
  Geometry? _geom;

  CoordinateSequence _pts;

  int start = 0;

  int end = 0;

  FacetSequence(this._geom, this._pts, [this.start = 0, this.end = 0]);

  FacetSequence.of(CoordinateSequence pts, int start)
      : this(null, pts, start, start + 1);

  Envelope getEnvelope() {
    Envelope env = Envelope();
    for (int i = start; i < end; i++) {
      env.expandToIncludePoint(_pts.getX(i), _pts.getY(i));
    }
    return env;
  }

  int size() {
    return end - start;
  }

  Coordinate getCoordinate(int index) {
    return _pts.getCoordinate(start + index);
  }

  bool isPoint() {
    return (end - start) == 1;
  }

  double distance(FacetSequence facetSeq) {
    bool isPointV = isPoint();
    bool isPointOther = facetSeq.isPoint();
    double distance;
    if (isPointV && isPointOther) {
      Coordinate pt = _pts.getCoordinate(start);
      Coordinate seqPt = facetSeq._pts.getCoordinate(facetSeq.start);
      distance = pt.distance(seqPt);
    } else if (isPointV) {
      Coordinate pt = _pts.getCoordinate(start);
      distance = computeDistancePointLine(pt, facetSeq, null);
    } else if (isPointOther) {
      Coordinate seqPt = facetSeq._pts.getCoordinate(facetSeq.start);
      distance = computeDistancePointLine(seqPt, this, null);
    } else {
      distance = computeDistanceLineLine(facetSeq, null);
    }
    return distance;
  }

  List<GeometryLocation> nearestLocations(FacetSequence facetSeq) {
    bool isPointV = isPoint();
    bool isPointOther = facetSeq.isPoint();
    List<GeometryLocation?> locs = List.filled(2, null);
    if (isPointV && isPointOther) {
      Coordinate pt = _pts.getCoordinate(start);
      Coordinate seqPt = facetSeq._pts.getCoordinate(facetSeq.start);
      locs[0] = GeometryLocation(_geom, start, Coordinate.of(pt));
      locs[1] = GeometryLocation(
          facetSeq._geom, facetSeq.start, Coordinate.of(seqPt));
    } else if (isPointV) {
      Coordinate pt = _pts.getCoordinate(start);
      computeDistancePointLine(pt, facetSeq, locs);
    } else if (isPointOther) {
      Coordinate seqPt = facetSeq._pts.getCoordinate(facetSeq.start);
      computeDistancePointLine(seqPt, this, locs);
      GeometryLocation tmp = locs[0]!;
      locs[0] = locs[1];
      locs[1] = tmp;
    } else {
      computeDistanceLineLine(facetSeq, locs);
    }
    return locs.cast();
  }

  double computeDistanceLineLine(
      FacetSequence facetSeq, List<GeometryLocation?>? locs) {
    double minDistance = double.maxFinite;
    for (int i = start; i < (end - 1); i++) {
      Coordinate p0 = _pts.getCoordinate(i);
      Coordinate p1 = _pts.getCoordinate(i + 1);
      for (int j = facetSeq.start; j < (facetSeq.end - 1); j++) {
        Coordinate q0 = facetSeq._pts.getCoordinate(j);
        Coordinate q1 = facetSeq._pts.getCoordinate(j + 1);
        double dist = Distance.segmentToSegment(p0, p1, q0, q1);
        if (dist < minDistance) {
          minDistance = dist;
          if (locs != null) {
            updateNearestLocationsLineLine(
                i, p0, p1, facetSeq, j, q0, q1, locs);
          }

          if (minDistance <= 0.0) {
            return minDistance;
          }
        }
      }
    }
    return minDistance;
  }

  void updateNearestLocationsLineLine(
    int i,
    Coordinate p0,
    Coordinate p1,
    FacetSequence facetSeq,
    int j,
    Coordinate q0,
    Coordinate q1,
    List<GeometryLocation?> locs,
  ) {
    LineSegment seg0 = LineSegment(p0, p1);
    LineSegment seg1 = LineSegment(q0, q1);
    final closestPt = seg0.closestPoints(seg1);
    locs[0] = GeometryLocation(_geom, i, Coordinate.of(closestPt[0]));
    locs[1] = GeometryLocation(facetSeq._geom, j, Coordinate.of(closestPt[1]));
  }

  double computeDistancePointLine(
      Coordinate pt, FacetSequence facetSeq, List<GeometryLocation?>? locs) {
    double minDistance = double.maxFinite;
    for (int i = facetSeq.start; i < (facetSeq.end - 1); i++) {
      Coordinate q0 = facetSeq._pts.getCoordinate(i);
      Coordinate q1 = facetSeq._pts.getCoordinate(i + 1);
      double dist = Distance.pointToSegment(pt, q0, q1);
      if (dist < minDistance) {
        minDistance = dist;
        if (locs != null) {
          updateNearestLocationsPointLine(pt, facetSeq, i, q0, q1, locs);
        }

        if (minDistance <= 0.0) {
          return minDistance;
        }
      }
    }
    return minDistance;
  }

  void updateNearestLocationsPointLine(
    Coordinate pt,
    FacetSequence facetSeq,
    int i,
    Coordinate q0,
    Coordinate q1,
    List<GeometryLocation?> locs,
  ) {
    locs[0] = GeometryLocation(_geom, start, Coordinate.of(pt));
    LineSegment seg = LineSegment(q0, q1);
    Coordinate segClosestPoint = seg.closestPoint(pt);
    locs[1] =
        GeometryLocation(facetSeq._geom, i, Coordinate.of(segClosestPoint));
  }
}
