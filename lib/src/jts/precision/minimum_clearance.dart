import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/distance.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/index/strtree/item_distance.dart';
import 'package:dts/src/jts/operation/distance/facet_sequence.dart';
import 'package:dts/src/jts/operation/distance/facet_sequence_tree_builder.dart';

class MinimumClearance {
  static double getDistance2(Geometry g) {
    MinimumClearance rp = MinimumClearance(g);
    return rp.getDistance();
  }

  static Geometry getLineS(Geometry g) {
    MinimumClearance rp = MinimumClearance(g);
    return rp.getLine();
  }

  Geometry inputGeom;

  double _minClearance = 0;

  Array<Coordinate?>? _minClearancePts;

  MinimumClearance(this.inputGeom);

  double getDistance() {
    compute();
    return _minClearance;
  }

  LineString getLine() {
    compute();
    if ((_minClearancePts == null) || (_minClearancePts![0] == null)) {
      return inputGeom.factory.createLineString();
    }

    return inputGeom.factory.createLineString2(_minClearancePts!.asArray());
  }

  void compute() {
    if (_minClearancePts != null) {
      return;
    }

    _minClearancePts = Array(2);
    _minClearance = double.maxFinite;
    if (inputGeom.isEmpty()) {
      return;
    }
    final geomTree = FacetSequenceTreeBuilder.build(inputGeom);
    final nearest = geomTree.nearestNeighbour(MinClearanceDistance())!;
    final mcd = MinClearanceDistance();
    _minClearance = mcd.distance2(nearest[0], nearest[1]);
    _minClearancePts = mcd.getCoordinates();
  }
}

class MinClearanceDistance implements ItemDistance<FacetSequence, dynamic> {
  double _minDist = double.maxFinite;

  final Array<Coordinate> _minPts = Array(2);

  Array<Coordinate> getCoordinates() {
    return _minPts;
  }

  @override
  double distance(final b1, final b2) {
    _minDist = double.maxFinite;
    return distance2(b1.item, b2.item);
  }

  double distance2(FacetSequence fs1, FacetSequence fs2) {
    vertexDistance(fs1, fs2);
    if ((fs1.size() == 1) && (fs2.size() == 1)) return _minDist;

    if (_minDist <= 0.0) return _minDist;

    segmentDistance(fs1, fs2);
    if (_minDist <= 0.0) return _minDist;

    segmentDistance(fs2, fs1);
    return _minDist;
  }

  double vertexDistance(FacetSequence fs1, FacetSequence fs2) {
    for (int i1 = 0; i1 < fs1.size(); i1++) {
      for (int i2 = 0; i2 < fs2.size(); i2++) {
        Coordinate p1 = fs1.getCoordinate(i1);
        Coordinate p2 = fs2.getCoordinate(i2);
        if (!p1.equals2D(p2)) {
          double d = p1.distance(p2);
          if (d < _minDist) {
            _minDist = d;
            _minPts[0] = p1;
            _minPts[1] = p2;
            if (d == 0.0) return d;
          }
        }
      }
    }
    return _minDist;
  }

  double segmentDistance(FacetSequence fs1, FacetSequence fs2) {
    for (int i1 = 0; i1 < fs1.size(); i1++) {
      for (int i2 = 1; i2 < fs2.size(); i2++) {
        Coordinate p = fs1.getCoordinate(i1);
        Coordinate seg0 = fs2.getCoordinate(i2 - 1);
        Coordinate seg1 = fs2.getCoordinate(i2);
        if (!(p.equals2D(seg0) || p.equals2D(seg1))) {
          double d = Distance.pointToSegment(p, seg0, seg1);
          if (d < _minDist) {
            _minDist = d;
            updatePts(p, seg0, seg1);
            if (d == 0.0) return d;
          }
        }
      }
    }
    return _minDist;
  }

  void updatePts(Coordinate p, Coordinate seg0, Coordinate seg1) {
    _minPts[0] = p;
    LineSegment seg = LineSegment(seg0, seg1);
    _minPts[1] = Coordinate.of(seg.closestPoint(p));
  }
}
