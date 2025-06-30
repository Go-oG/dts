import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_collection.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'point_pair_distance.dart';

class DistanceToPoint {
  DistanceToPoint._();

  static void computeDistance(Geometry geom, Coordinate pt, PointPairDistance ptDist) {
    if (geom is LineString) {
      computeDistance2(geom, pt, ptDist);
    } else if (geom is Polygon) {
      computeDistance4(geom, pt, ptDist);
    } else if (geom is GeomCollection) {
      GeomCollection gc = geom;
      for (int i = 0; i < gc.getNumGeometries(); i++) {
        Geometry g = gc.getGeometryN(i);
        computeDistance(g, pt, ptDist);
      }
    } else {
      ptDist.setMinimum2(geom.getCoordinate()!, pt);
    }
  }

  static void computeDistance2(LineString line, Coordinate pt, PointPairDistance ptDist) {
    LineSegment tempSegment = LineSegment.empty();
    Array<Coordinate> coords = line.getCoordinates();
    for (int i = 0; i < (coords.length - 1); i++) {
      tempSegment.setCoordinates2(coords[i], coords[i + 1]);
      Coordinate closestPt = tempSegment.closestPoint(pt);
      ptDist.setMinimum2(closestPt, pt);
    }
  }

  static void computeDistance3(LineSegment segment, Coordinate pt, PointPairDistance ptDist) {
    Coordinate closestPt = segment.closestPoint(pt);
    ptDist.setMinimum2(closestPt, pt);
  }

  static void computeDistance4(Polygon poly, Coordinate pt, PointPairDistance ptDist) {
    computeDistance2(poly.getExteriorRing(), pt, ptDist);
    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      computeDistance2(poly.getInteriorRingN(i), pt, ptDist);
    }
  }
}
