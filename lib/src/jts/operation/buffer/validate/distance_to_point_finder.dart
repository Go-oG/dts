import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/operation/buffer/validate/point_pair_distance.dart';

class DistanceToPointFinder {
  static void computeDistance(
      Geometry geom, Coordinate pt, OpPointPairDistance ptDist) {
    if (geom is LineString) {
      computeDistance3(geom, pt, ptDist);
    } else if (geom is Polygon) {
      computeDistance4(geom, pt, ptDist);
    } else if (geom is GeometryCollection) {
      GeometryCollection gc = geom;
      for (int i = 0; i < gc.getNumGeometries(); i++) {
        Geometry g = gc.getGeometryN(i);
        computeDistance(g, pt, ptDist);
      }
    } else {
      ptDist.setMinimum2(geom.getCoordinate()!, pt);
    }
  }

  static void computeDistance3(
      LineString line, Coordinate pt, OpPointPairDistance ptDist) {
    List<Coordinate> coords = line.getCoordinates();
    LineSegment tempSegment = LineSegment.empty();
    for (int i = 0; i < (coords.length - 1); i++) {
      tempSegment.setCoordinates2(coords[i], coords[i + 1]);
      Coordinate closestPt = tempSegment.closestPoint(pt);
      ptDist.setMinimum2(closestPt, pt);
    }
  }

  static void computeDistance2(
      LineSegment segment, Coordinate pt, OpPointPairDistance ptDist) {
    Coordinate closestPt = segment.closestPoint(pt);
    ptDist.setMinimum2(closestPt, pt);
  }

  static void computeDistance4(
      Polygon poly, Coordinate pt, OpPointPairDistance ptDist) {
    computeDistance3(poly.getExteriorRing(), pt, ptDist);
    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      computeDistance3(poly.getInteriorRingN(i), pt, ptDist);
    }
  }
}
