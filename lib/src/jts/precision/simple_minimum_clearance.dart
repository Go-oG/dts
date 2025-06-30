 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/distance.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';

class SimpleMinimumClearance {
  static double getDistance2(Geometry g) {
    SimpleMinimumClearance rp = SimpleMinimumClearance(g);
    return rp.getDistance();
  }

  static Geometry getLine2(Geometry g) {
    SimpleMinimumClearance rp = SimpleMinimumClearance(g);
    return rp.getLine();
  }

  Geometry inputGeom;

  double minClearance = 0;

  Array<Coordinate>? minClearancePts;

  SimpleMinimumClearance(this.inputGeom);

  double getDistance() {
    compute();
    return minClearance;
  }

  LineString getLine() {
    compute();
    return inputGeom.factory.createLineString2(minClearancePts);
  }

  void compute() {
    if (minClearancePts != null) {
      return;
    }

    minClearancePts = Array(2);
    minClearance = double.maxFinite;
    inputGeom.apply(VertexCoordinateFilter(this));
  }

  void updateClearance(double candidateValue, Coordinate p0, Coordinate p1) {
    if (candidateValue < minClearance) {
      minClearance = candidateValue;
      minClearancePts![0] = Coordinate.of(p0);
      minClearancePts![1] = Coordinate.of(p1);
    }
  }

  void updateClearance2(double candidateValue, Coordinate p, Coordinate seg0, Coordinate seg1) {
    if (candidateValue < minClearance) {
      minClearance = candidateValue;
      minClearancePts![0] = Coordinate.of(p);
      LineSegment seg = LineSegment(seg0, seg1);
      minClearancePts![1] = Coordinate.of(seg.closestPoint(p));
    }
  }
}

class VertexCoordinateFilter implements CoordinateFilter {
  SimpleMinimumClearance smc;

  VertexCoordinateFilter(this.smc);

  @override
  void filter(Coordinate coord) {
    smc.inputGeom.apply2(ComputeMCCoordinateSequenceFilter(smc, coord));
  }
}

class ComputeMCCoordinateSequenceFilter implements CoordinateSequenceFilter {
  SimpleMinimumClearance smc;

  final Coordinate _queryPt;

  ComputeMCCoordinateSequenceFilter(this.smc, this._queryPt);

  @override
  void filter(CoordinateSequence seq, int i) {
    checkVertexDistance(seq.getCoordinate(i));
    if (i > 0) {
      checkSegmentDistance(seq.getCoordinate(i - 1), seq.getCoordinate(i));
    }
  }

  void checkVertexDistance(Coordinate vertex) {
    double vertexDist = vertex.distance(_queryPt);
    if (vertexDist > 0) {
      smc.updateClearance(vertexDist, _queryPt, vertex);
    }
  }

  void checkSegmentDistance(Coordinate seg0, Coordinate seg1) {
    if (_queryPt.equals2D(seg0) || _queryPt.equals2D(seg1)) return;

    double segDist = Distance.pointToSegment(_queryPt, seg1, seg0);
    if (segDist > 0) smc.updateClearance2(segDist, _queryPt, seg1, seg0);
  }

  @override
  bool isDone() {
    return false;
  }

  @override
  bool isGeometryChanged() {
    return false;
  }
}
