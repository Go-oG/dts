import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/construct/maximum_inscribed_circle.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import '../geom/geom_filter.dart';
import 'coverage_union.dart';

class CoverageGapFinder {
  static Geometry findGapsS(Array<Geometry> coverage, double gapWidth) {
    CoverageGapFinder finder = CoverageGapFinder(coverage);
    return finder.findGaps(gapWidth);
  }

  final Array<Geometry> _coverage;

  CoverageGapFinder(this._coverage);

  Geometry findGaps(double gapWidth) {
    Geometry? union = CoverageUnion.union(_coverage);
    List<Polygon> polygons = PolygonExtracter.getPolygons(union!);
    List<LineString> gapLines = [];
    for (Polygon poly in polygons) {
      for (int i = 0; i < poly.getNumInteriorRing(); i++) {
        LinearRing hole = poly.getInteriorRingN(i);
        if (_isGap(hole, gapWidth)) {
          gapLines.add(_copyLine(hole));
        }
      }
    }
    return union.factory.buildGeometry(gapLines);
  }

  LineString _copyLine(LinearRing hole) {
    Array<Coordinate> pts = hole.getCoordinates();
    return hole.factory.createLineString2(pts);
  }

  bool _isGap(LinearRing hole, double gapWidth) {
    Geometry holePoly = hole.factory.createPolygon(hole);
    if (gapWidth <= 0.0) {
      return false;
    }

    double tolerance = gapWidth / 100;
    LineString line = MaximumInscribedCircle.getRadiusLineS(holePoly, tolerance);
    double width = line.getLength() * 2;
    return width <= gapWidth;
  }
}
