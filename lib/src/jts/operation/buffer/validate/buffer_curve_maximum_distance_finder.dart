import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/operation/buffer/validate/point_pair_distance.dart';

import 'distance_to_point_finder.dart';

class BufferCurveMaximumDistanceFinder {
  Geometry inputGeom;

  final _maxPtDist = OpPointPairDistance();

  BufferCurveMaximumDistanceFinder(this.inputGeom);

  double findDistance(Geometry bufferCurve) {
    computeMaxVertexDistance(bufferCurve);
    computeMaxMidpointDistance(bufferCurve);
    return _maxPtDist.getDistance();
  }

  OpPointPairDistance getDistancePoints() {
    return _maxPtDist;
  }

  void computeMaxVertexDistance(Geometry curve) {
    final distFilter = MaxPointDistanceFilter(inputGeom);
    curve.apply(distFilter);
    _maxPtDist.setMaximum(distFilter.getMaxPointDistance());
  }

  void computeMaxMidpointDistance(Geometry curve) {
    final distFilter = MaxMidpointDistanceFilter(inputGeom);
    curve.apply2(distFilter);
    _maxPtDist.setMaximum(distFilter.getMaxPointDistance());
  }
}

class MaxMidpointDistanceFilter implements CoordinateSequenceFilter {
  OpPointPairDistance maxPtDist = OpPointPairDistance();

  OpPointPairDistance minPtDist = OpPointPairDistance();

  Geometry geom;

  MaxMidpointDistanceFilter(this.geom);

  @override
  void filter(CoordinateSequence seq, int index) {
    if (index == 0) return;

    Coordinate p0 = seq.getCoordinate(index - 1);
    Coordinate p1 = seq.getCoordinate(index);
    Coordinate midPt = Coordinate((p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
    minPtDist.initialize();
    DistanceToPointFinder.computeDistance(geom, midPt, minPtDist);
    maxPtDist.setMaximum(minPtDist);
  }

  @override
  bool isGeometryChanged() {
    return false;
  }

  @override
  bool isDone() {
    return false;
  }

  OpPointPairDistance getMaxPointDistance() {
    return maxPtDist;
  }
}

class MaxPointDistanceFilter implements CoordinateFilter {
  final maxPtDist = OpPointPairDistance();

  final _minPtDist = OpPointPairDistance();

  Geometry geom;

  MaxPointDistanceFilter(this.geom);

  @override
  void filter(Coordinate pt) {
    _minPtDist.initialize();
    DistanceToPointFinder.computeDistance(geom, pt, _minPtDist);
    maxPtDist.setMaximum(_minPtDist);
  }

  OpPointPairDistance getMaxPointDistance() {
    return maxPtDist;
  }
}
