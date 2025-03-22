 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/point_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';

import 'polygonal_linework_extracter.dart';

class FuzzyPointLocator {
  final Geometry _g;

  final double _boundaryDistanceTolerance;

  late MultiLineString _linework;

  PointLocator ptLocator = PointLocator.empty();

  LineSegment seg = LineSegment.empty();

  FuzzyPointLocator(this._g, this._boundaryDistanceTolerance) {
    _linework = extractLinework(_g);
  }

  int getLocation(Coordinate pt) {
    if (isWithinToleranceOfBoundary(pt)) return Location.boundary;

    return ptLocator.locate(pt, _g);
  }

  MultiLineString extractLinework(Geometry g) {
    final extracter = PolygonalLineworkExtracter();
    g.apply3(extracter);
    final linework = extracter.getLinework();
    Array<LineString> lines = GeometryFactory.toLineStringArray(linework);
    return g.factory.createMultiLineString2(lines);
  }

  bool isWithinToleranceOfBoundary(Coordinate pt) {
    for (int i = 0; i < _linework.getNumGeometries(); i++) {
      LineString line = _linework.getGeometryN(i);
      CoordinateSequence seq = line.getCoordinateSequence();
      for (int j = 0; j < (seq.size() - 1); j++) {
        seq.getCoordinate2(j, seg.p0);
        seq.getCoordinate2(j + 1, seg.p1);
        double dist = seg.distance(pt);
        if (dist <= _boundaryDistanceTolerance) {
          return true;
        }
      }
    }
    return false;
  }
}
