import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/cgalgorithms.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_collection.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/operation/distance/geometry_location.dart';

import 'planar_polygon3_d.dart';

class Distance3DOp {
  static double distance2(Geometry g0, Geometry g1) {
    Distance3DOp distOp = Distance3DOp(g0, g1);
    return distOp.distance();
  }

  static bool isWithinDistance(Geometry g0, Geometry g1, double distance) {
    Distance3DOp distOp = Distance3DOp(g0, g1, distance);
    return distOp.distance() <= distance;
  }

  static Array<Coordinate> nearestPointsS(Geometry g0, Geometry g1) {
    Distance3DOp distOp = Distance3DOp(g0, g1);
    return distOp.nearestPoints();
  }

  late Array<Geometry> geom;

  double terminateDistance = 0.0;

  Array<GeometryLocation>? minDistanceLocation;

  double minDistance = double.maxFinite;

  bool isDone = false;

  Distance3DOp(Geometry g0, Geometry g1, [this.terminateDistance = 0]) {
    geom = Array(2);
    geom[0] = g0;
    geom[1] = g1;
  }

  double distance() {
    if (geom[0].isEmpty() || geom[1].isEmpty()) {
      return 0.0;
    }
    computeMinDistance();
    return minDistance;
  }

  Array<Coordinate> nearestPoints() {
    computeMinDistance();
    Array<Coordinate> nearestPts = [
      minDistanceLocation![0].getCoordinate(),
      minDistanceLocation![1].getCoordinate()
    ].toArray();
    return nearestPts;
  }

  Array<GeometryLocation> nearestLocations() {
    computeMinDistance();
    return minDistanceLocation!;
  }

  void updateDistance(double dist, GeometryLocation loc0, GeometryLocation loc1, bool flip) {
    minDistance = dist;
    int index = (flip) ? 1 : 0;
    minDistanceLocation![index] = loc0;
    minDistanceLocation![1 - index] = loc1;
    if (minDistance < terminateDistance) {
      isDone = true;
    }
  }

  void computeMinDistance() {
    if (minDistanceLocation != null) {
      return;
    }

    minDistanceLocation = Array(2);
    int geomIndex = mostPolygonalIndex();
    bool flip = geomIndex == 1;
    computeMinDistanceMultiMulti(geom[geomIndex], geom[1 - geomIndex], flip);
  }

  int mostPolygonalIndex() {
    int dim0 = geom[0].getDimension();
    int dim1 = geom[1].getDimension();
    if ((dim0 >= 2) && (dim1 >= 2)) {
      if (geom[0].getNumPoints() > geom[1].getNumPoints()) {
        return 0;
      }

      return 1;
    }
    if (dim0 >= 2) {
      return 0;
    }

    if (dim1 >= 2) {
      return 1;
    }

    return 0;
  }

  void computeMinDistanceMultiMulti(Geometry g0, Geometry g1, bool flip) {
    if (g0 is GeomCollection) {
      int n = g0.getNumGeometries();
      for (int i = 0; i < n; i++) {
        Geometry g = g0.getGeometryN(i);
        computeMinDistanceMultiMulti(g, g1, flip);
        if (isDone) {
          return;
        }
      }
    } else {
      if (g0.isEmpty()) {
        return;
      }

      if (g0 is Polygon) {
        _computeMinDistanceOneMulti2(polyPlane(g0), g1, flip);
      } else {
        _computeMinDistanceOneMulti(g0, g1, flip);
      }
    }
  }

  void _computeMinDistanceOneMulti(Geometry g0, Geometry g1, bool flip) {
    if (g1 is GeomCollection) {
      int n = g1.getNumGeometries();
      for (int i = 0; i < n; i++) {
        Geometry g = g1.getGeometryN(i);
        _computeMinDistanceOneMulti(g0, g, flip);
        if (isDone) {
          return;
        }
      }
    } else {
      computeMinDistance2(g0, g1, flip);
    }
  }

  void _computeMinDistanceOneMulti2(PlanarPolygon3D poly, Geometry geom, bool flip) {
    if (geom is GeomCollection) {
      int n = geom.getNumGeometries();
      for (int i = 0; i < n; i++) {
        Geometry g = geom.getGeometryN(i);
        _computeMinDistanceOneMulti2(poly, g, flip);
        if (isDone) {
          return;
        }
      }
    } else {
      if (geom is Point) {
        computeMinDistancePolygonPoint(poly, geom, flip);
        return;
      }
      if (geom is LineString) {
        computeMinDistancePolygonLine(poly, geom, flip);
        return;
      }
      if (geom is Polygon) {
        computeMinDistancePolygonPolygon(poly, geom, flip);
        return;
      }
    }
  }

  static PlanarPolygon3D polyPlane(Polygon poly) {
    return PlanarPolygon3D(poly);
  }

  void computeMinDistance2(Geometry g0, Geometry g1, bool flip) {
    if (g0 is Point) {
      if (g1 is Point) {
        computeMinDistancePointPoint(g0, g1, flip);
        return;
      }
      if (g1 is LineString) {
        computeMinDistanceLinePoint(g1, g0, !flip);
        return;
      }
      if (g1 is Polygon) {
        computeMinDistancePolygonPoint(polyPlane(g1), g0, !flip);
        return;
      }
    }
    if (g0 is LineString) {
      if (g1 is Point) {
        computeMinDistanceLinePoint(g0, g1, flip);
        return;
      }
      if (g1 is LineString) {
        computeMinDistanceLineLine(g0, g1, flip);
        return;
      }
      if (g1 is Polygon) {
        computeMinDistancePolygonLine(polyPlane(g1), g0, !flip);
        return;
      }
    }
    if (g0 is Polygon) {
      if (g1 is Point) {
        computeMinDistancePolygonPoint(polyPlane(g0), g1, flip);
        return;
      }
      if (g1 is LineString) {
        computeMinDistancePolygonLine(polyPlane(g0), g1, flip);
        return;
      }
      if (g1 is Polygon) {
        computeMinDistancePolygonPolygon(polyPlane(g0), g1, flip);
        return;
      }
    }
  }

  void computeMinDistancePolygonPolygon(PlanarPolygon3D poly0, Polygon poly1, bool flip) {
    computeMinDistancePolygonRings(poly0, poly1, flip);
    if (isDone) {
      return;
    }

    PlanarPolygon3D polyPlane1 = PlanarPolygon3D(poly1);
    computeMinDistancePolygonRings(polyPlane1, poly0.getPolygon(), flip);
  }

  void computeMinDistancePolygonRings(PlanarPolygon3D poly, Polygon ringPoly, bool flip) {
    computeMinDistancePolygonLine(poly, ringPoly.getExteriorRing(), flip);
    if (isDone) {
      return;
    }

    int nHole = ringPoly.getNumInteriorRing();
    for (int i = 0; i < nHole; i++) {
      computeMinDistancePolygonLine(poly, ringPoly.getInteriorRingN(i), flip);
      if (isDone) {
        return;
      }
    }
  }

  void computeMinDistancePolygonLine(PlanarPolygon3D poly, LineString line, bool flip) {
    Coordinate? intPt = intersection(poly, line);
    if (intPt != null) {
      updateDistance(
          0, GeometryLocation(poly.getPolygon(), 0, intPt), GeometryLocation(line, 0, intPt), flip);
      return;
    }
    computeMinDistanceLineLine(poly.getPolygon().getExteriorRing(), line, flip);
    if (isDone) {
      return;
    }

    int nHole = poly.getPolygon().getNumInteriorRing();
    for (int i = 0; i < nHole; i++) {
      computeMinDistanceLineLine(poly.getPolygon().getInteriorRingN(i), line, flip);
      if (isDone) {
        return;
      }
    }
  }

  Coordinate? intersection(PlanarPolygon3D poly, LineString line) {
    CoordinateSequence seq = line.getCoordinateSequence();
    if (seq.size() == 0) {
      return null;
    }

    Coordinate p0 = Coordinate();
    seq.getCoordinate2(0, p0);
    double d0 = poly.getPlane().orientedDistance(p0);
    Coordinate p1 = Coordinate();
    for (int i = 0; i < (seq.size() - 1); i++) {
      seq.getCoordinate2(i, p0);
      seq.getCoordinate2(i + 1, p1);
      double d1 = poly.getPlane().orientedDistance(p1);
      if ((d0 * d1) > 0) {
        continue;
      }

      Coordinate intPt = segmentPoint(p0, p1, d0, d1);
      if (poly.intersects(intPt)) {
        return intPt;
      }
      d0 = d1;
    }
    return null;
  }

  void computeMinDistancePolygonPoint(PlanarPolygon3D polyPlane, Point point, bool flip) {
    Coordinate pt = point.getCoordinate()!;
    LineString shell = polyPlane.getPolygon().getExteriorRing();
    if (polyPlane.intersects2(pt, shell)) {
      int nHole = polyPlane.getPolygon().getNumInteriorRing();
      for (int i = 0; i < nHole; i++) {
        LineString hole = polyPlane.getPolygon().getInteriorRingN(i);
        if (polyPlane.intersects2(pt, hole)) {
          computeMinDistanceLinePoint(hole, point, flip);
          return;
        }
      }
      double dist = Math.abs(polyPlane.getPlane().orientedDistance(pt));
      updateDistance(dist, GeometryLocation(polyPlane.getPolygon(), 0, pt),
          GeometryLocation(point, 0, pt), flip);
    }
    computeMinDistanceLinePoint(shell, point, flip);
  }

  void computeMinDistanceLineLine(LineString line0, LineString line1, bool flip) {
    Array<Coordinate> coord0 = line0.getCoordinates();
    Array<Coordinate> coord1 = line1.getCoordinates();
    for (int i = 0; i < (coord0.length - 1); i++) {
      for (int j = 0; j < (coord1.length - 1); j++) {
        double dist = CGAlgorithms3D.distanceSegmentSegment(
            coord0[i], coord0[i + 1], coord1[j], coord1[j + 1]);
        if (dist < minDistance) {
          minDistance = dist;
          LineSegment seg0 = LineSegment(coord0[i], coord0[i + 1]);
          LineSegment seg1 = LineSegment(coord1[j], coord1[j + 1]);
          Array<Coordinate> closestPt = seg0.closestPoints(seg1);
          updateDistance(
            dist,
            GeometryLocation(line0, i, closestPt[0]),
            GeometryLocation(line1, j, closestPt[1]),
            flip,
          );
        }
        if (isDone) {
          return;
        }
      }
    }
  }

  void computeMinDistanceLinePoint(LineString line, Point point, bool flip) {
    Array<Coordinate> lineCoord = line.getCoordinates();
    Coordinate coord = point.getCoordinate()!;
    for (int i = 0; i < (lineCoord.length - 1); i++) {
      double dist = CGAlgorithms3D.distancePointSegment(coord, lineCoord[i], lineCoord[i + 1]);
      if (dist < minDistance) {
        LineSegment seg = LineSegment(lineCoord[i], lineCoord[i + 1]);
        Coordinate segClosestPoint = seg.closestPoint(coord);
        updateDistance(dist, GeometryLocation(line, i, segClosestPoint),
            GeometryLocation(point, 0, coord), flip);
      }
      if (isDone) {
        return;
      }
    }
  }

  void computeMinDistancePointPoint(Point point0, Point point1, bool flip) {
    double dist = CGAlgorithms3D.distance(point0.getCoordinate()!, point1.getCoordinate()!);
    if (dist < minDistance) {
      updateDistance(
        dist,
        GeometryLocation(point0, 0, point0.getCoordinate()!),
        GeometryLocation(point1, 0, point1.getCoordinate()!),
        flip,
      );
    }
  }

  static Coordinate segmentPoint(Coordinate p0, Coordinate p1, double d0, double d1) {
    if (d0 <= 0) {
      return Coordinate.of(p0);
    }

    if (d1 <= 0) {
      return Coordinate.of(p1);
    }

    double f = Math.abs(d0) / (Math.abs(d0) + Math.abs(d1));
    double intx = p0.x + (f * (p1.x - p0.x));
    double inty = p0.y + (f * (p1.y - p0.y));
    double intz = p0.z + (f * (p1.z - p0.z));
    return Coordinate(intx, inty, intz);
  }
}
