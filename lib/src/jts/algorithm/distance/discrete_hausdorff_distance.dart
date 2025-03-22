 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_string.dart';

import 'distance_to_point.dart';
import 'point_pair_distance.dart';

class DiscreteHausdorffDistance {
  static double distanceS(Geometry g0, Geometry g1) {
    return DiscreteHausdorffDistance(g0, g1).distance();
  }

  static double distanceS2(Geometry g0, Geometry g1, double densifyFrac) {
    final dist = DiscreteHausdorffDistance(g0, g1);
    dist.setDensifyFraction(densifyFrac);
    return dist.distance();
  }

  static LineString distanceLine(Geometry g0, Geometry g1) {
    final dist = DiscreteHausdorffDistance(g0, g1);
    dist.distance();
    return g0.factory.createLineString2(dist.getCoordinates());
  }

  static LineString distanceLine2(Geometry g0, Geometry g1, double densifyFrac) {
    final dist = DiscreteHausdorffDistance(g0, g1);
    dist.setDensifyFraction(densifyFrac);
    dist.distance();
    return g0.factory.createLineString2(dist.getCoordinates());
  }

  static double orientedDistanceS(Geometry g0, Geometry g1) {
    final dist = DiscreteHausdorffDistance(g0, g1);
    return dist.orientedDistance();
  }

  static double orientedDistanceS2(Geometry g0, Geometry g1, double densifyFrac) {
    final dist = DiscreteHausdorffDistance(g0, g1);
    dist.setDensifyFraction(densifyFrac);
    return dist.orientedDistance();
  }

  static LineString orientedDistanceLine(Geometry g0, Geometry g1) {
    final dist = DiscreteHausdorffDistance(g0, g1);
    dist.orientedDistance();
    return g0.factory.createLineString2(dist.getCoordinates());
  }

  static LineString orientedDistanceLine2(Geometry g0, Geometry g1, double densifyFrac) {
    final dist = DiscreteHausdorffDistance(g0, g1);
    dist.setDensifyFraction(densifyFrac);
    dist.orientedDistance();
    return g0.factory.createLineString2(dist.getCoordinates());
  }

  final Geometry _g0;

  final Geometry _g1;

  final PointPairDistance _ptDist = PointPairDistance();

  double _densifyFrac = 0.0;

  DiscreteHausdorffDistance(this._g0, this._g1);

  void setDensifyFraction(double densifyFrac) {
    if ((densifyFrac > 1.0) || (densifyFrac <= 0.0)) {
      throw ("Fraction is not in range (0.0 - 1.0]");
    }
    _densifyFrac = densifyFrac;
  }

  double distance() {
    _compute(_g0, _g1);
    return _ptDist.getDistance();
  }

  double orientedDistance() {
    _computeOrientedDistance(_g0, _g1, _ptDist);
    return _ptDist.getDistance();
  }

  Array<Coordinate> getCoordinates() {
    return _ptDist.getCoordinates();
  }

  void _compute(Geometry g0, Geometry g1) {
    _computeOrientedDistance(g0, g1, _ptDist);
    _computeOrientedDistance(g1, g0, _ptDist);
  }

  void _computeOrientedDistance(Geometry discreteGeom, Geometry geom, PointPairDistance ptDist) {
    _MaxPointDistanceFilter distFilter = _MaxPointDistanceFilter(geom);
    discreteGeom.apply(distFilter);
    ptDist.setMaximum(distFilter.getMaxPointDistance());
    if (_densifyFrac > 0) {
      _MaxDensifiedByFractionDistanceFilter fracFilter = _MaxDensifiedByFractionDistanceFilter(geom, _densifyFrac);
      discreteGeom.apply2(fracFilter);
      ptDist.setMaximum(fracFilter.getMaxPointDistance());
    }
  }
}

class _MaxPointDistanceFilter implements CoordinateFilter {
  PointPairDistance maxPtDist = PointPairDistance();

  PointPairDistance minPtDist = PointPairDistance();

  Geometry geom;

  _MaxPointDistanceFilter(this.geom);

  @override
  void filter(Coordinate pt) {
    minPtDist.initialize();
    DistanceToPoint.computeDistance(geom, pt, minPtDist);
    maxPtDist.setMaximum(minPtDist);
  }

  PointPairDistance getMaxPointDistance() {
    return maxPtDist;
  }
}

class _MaxDensifiedByFractionDistanceFilter implements CoordinateSequenceFilter {
  final maxPtDist = PointPairDistance();

  final minPtDist = PointPairDistance();

  final Geometry geom;

  int numSubSegs = 0;

  _MaxDensifiedByFractionDistanceFilter(this.geom, double fraction) {
    numSubSegs = Math.rint(1.0 / fraction);
  }

  @override
  void filter(CoordinateSequence seq, int index) {
    if (index == 0) {
      return;
    }

    Coordinate p0 = seq.getCoordinate(index - 1);
    Coordinate p1 = seq.getCoordinate(index);
    double delx = (p1.x - p0.x) / numSubSegs;
    double dely = (p1.y - p0.y) / numSubSegs;
    for (int i = 0; i < numSubSegs; i++) {
      double x = p0.x + (i * delx);
      double y = p0.y + (i * dely);
      Coordinate pt = Coordinate(x, y);
      minPtDist.initialize();
      DistanceToPoint.computeDistance(geom, pt, minPtDist);
      maxPtDist.setMaximum(minPtDist);
    }
  }

  @override
  bool isGeometryChanged() {
    return false;
  }

  @override
  bool isDone() {
    return false;
  }

  PointPairDistance getMaxPointDistance() {
    return maxPtDist;
  }
}
