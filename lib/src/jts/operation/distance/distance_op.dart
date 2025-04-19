import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/distance.dart';
import 'package:dts/src/jts/algorithm/point_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_filter.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/util/linear_component_extracter.dart';

import 'connected_element_location_filter.dart';
import 'geometry_location.dart';

class DistanceOp {
  static double distanceS(Geometry g0, Geometry g1) {
    DistanceOp distOp = DistanceOp(g0, g1);
    return distOp.distance();
  }

  static bool isWithinDistance(Geometry g0, Geometry g1, double distance) {
    double envDist = g0.getEnvelopeInternal().distance(g1.getEnvelopeInternal());
    if (envDist > distance) {
      return false;
    }

    DistanceOp distOp = DistanceOp(g0, g1, distance);
    return distOp.distance() <= distance;
  }

  static Array<Coordinate> nearestPoints2(Geometry g0, Geometry g1) {
    DistanceOp distOp = DistanceOp(g0, g1);
    return distOp.nearestPoints();
  }

  static Array<Coordinate> closestPoints2(Geometry g0, Geometry g1) {
    DistanceOp distOp = DistanceOp(g0, g1);
    return distOp.nearestPoints();
  }

  late Array<Geometry> _geom;

  final double _terminateDistance;

  final _ptLocator = PointLocator.empty();

  Array<GeometryLocation>? _minDistanceLocation;

  double minDistance = double.maxFinite;

  DistanceOp(Geometry g0, Geometry g1, [this._terminateDistance = 0]) {
    _geom = Array(2);
    _geom[0] = g0;
    _geom[1] = g1;
  }

  double distance() {
    if (_geom[0].isEmpty() || _geom[1].isEmpty()) {
      return 0.0;
    }

    if ((_geom[0] is Point) && (_geom[1] is Point)) {
      return _geom[0].getCoordinate()!.distance(_geom[1].getCoordinate()!);
    }
    computeMinDistance();
    return minDistance;
  }

  Array<Coordinate> nearestPoints() {
    computeMinDistance();
    Array<Coordinate> nearestPts = [
      _minDistanceLocation![0].getCoordinate(),
      _minDistanceLocation![1].getCoordinate()
    ].toArray();
    return nearestPts;
  }

  Array<Coordinate> closestPoints() {
    return nearestPoints();
  }

  Array<GeometryLocation> nearestLocations() {
    computeMinDistance();
    return _minDistanceLocation!;
  }

  Array<GeometryLocation> closestLocations() {
    return nearestLocations();
  }

  void updateMinDistance(Array<GeometryLocation?> locGeom, bool flip) {
    if (locGeom[0] == null) {
      return;
    }

    if (flip) {
      _minDistanceLocation![0] = locGeom[1]!;
      _minDistanceLocation![1] = locGeom[0]!;
    } else {
      _minDistanceLocation![0] = locGeom[0]!;
      _minDistanceLocation![1] = locGeom[1]!;
    }
  }

  void computeMinDistance() {
    if (_minDistanceLocation != null) {
      return;
    }

    _minDistanceLocation = Array(2);
    computeContainmentDistance();
    if (minDistance <= _terminateDistance) {
      return;
    }

    computeFacetDistance();
  }

  void computeContainmentDistance() {
    Array<GeometryLocation> locPtPoly = Array(2);
    computeContainmentDistance3(0, locPtPoly);
    if (minDistance <= _terminateDistance) {
      return;
    }

    computeContainmentDistance3(1, locPtPoly);
  }

  void computeContainmentDistance3(int polyGeomIndex, Array<GeometryLocation> locPtPoly) {
    Geometry polyGeom = _geom[polyGeomIndex];
    if (polyGeom.getDimension() < 2) {
      return;
    }

    int locationsIndex = 1 - polyGeomIndex;
    final polys = PolygonExtracter.getPolygons(polyGeom);
    if (polys.size > 0) {
      final insideLocs = ConnectedElementLocationFilter.getLocations(_geom[locationsIndex]);
      computeContainmentDistance4(insideLocs, polys, locPtPoly);
      if (minDistance <= _terminateDistance) {
        _minDistanceLocation![locationsIndex] = locPtPoly[0];
        _minDistanceLocation![polyGeomIndex] = locPtPoly[1];
        return;
      }
    }
  }

  void computeContainmentDistance4(
    List<GeometryLocation> locs,
    List<Polygon> polys,
    Array<GeometryLocation> locPtPoly,
  ) {
    for (int i = 0; i < locs.size; i++) {
      final loc = locs[i];
      for (int j = 0; j < polys.size; j++) {
        computeContainmentDistance2(loc, polys[j], locPtPoly);
        if (minDistance <= _terminateDistance) {
          return;
        }
      }
    }
  }

  void computeContainmentDistance2(
      GeometryLocation ptLoc, Polygon poly, Array<GeometryLocation> locPtPoly) {
    Coordinate pt = ptLoc.getCoordinate();
    if (Location.exterior != _ptLocator.locate(pt, poly)) {
      minDistance = 0.0;
      locPtPoly[0] = ptLoc;
      locPtPoly[1] = GeometryLocation.of(poly, pt);
      return;
    }
  }

  void computeFacetDistance() {
    Array<GeometryLocation?> locGeom = Array(2);
    final lines0 = LinearComponentExtracter.getLines(_geom[0]);
    final lines1 = LinearComponentExtracter.getLines(_geom[1]);
    final pts0 = PointExtracter.getPoints(_geom[0]);
    final pts1 = PointExtracter.getPoints(_geom[1]);
    computeMinDistanceLines(lines0, lines1, locGeom);
    updateMinDistance(locGeom, false);
    if (minDistance <= _terminateDistance) {
      return;
    }

    locGeom[0] = null;
    locGeom[1] = null;
    computeMinDistanceLinesPoints(lines0, pts1, locGeom);
    updateMinDistance(locGeom, false);
    if (minDistance <= _terminateDistance) {
      return;
    }

    locGeom[0] = null;
    locGeom[1] = null;
    computeMinDistanceLinesPoints(lines1, pts0, locGeom);
    updateMinDistance(locGeom, true);
    if (minDistance <= _terminateDistance) {
      return;
    }

    locGeom[0] = null;
    locGeom[1] = null;
    computeMinDistancePoints(pts0, pts1, locGeom);
    updateMinDistance(locGeom, false);
  }

  void computeMinDistanceLines(
      List<LineString> lines0, List<LineString> lines1, Array<GeometryLocation?> locGeom) {
    for (int i = 0; i < lines0.size; i++) {
      LineString line0 = lines0[i];
      for (int j = 0; j < lines1.size; j++) {
        LineString line1 = lines1[j];
        computeMinDistance2(line0, line1, locGeom);
        if (minDistance <= _terminateDistance) {
          return;
        }
      }
    }
  }

  void computeMinDistancePoints(
      List<Point> points0, List<Point> points1, Array<GeometryLocation?> locGeom) {
    for (int i = 0; i < points0.size; i++) {
      Point pt0 = points0[i];
      if (pt0.isEmpty()) {
        continue;
      }

      for (int j = 0; j < points1.size; j++) {
        Point pt1 = points1[j];
        if (pt1.isEmpty()) {
          continue;
        }

        double dist = pt0.getCoordinate()!.distance(pt1.getCoordinate()!);
        if (dist < minDistance) {
          minDistance = dist;
          locGeom[0] = GeometryLocation(pt0, 0, pt0.getCoordinate()!);
          locGeom[1] = GeometryLocation(pt1, 0, pt1.getCoordinate()!);
        }
        if (minDistance <= _terminateDistance) {
          return;
        }
      }
    }
  }

  void computeMinDistanceLinesPoints(
      List<LineString> lines, List<Point> points, Array<GeometryLocation?> locGeom) {
    for (int i = 0; i < lines.size; i++) {
      LineString line = lines[i];
      for (int j = 0; j < points.size; j++) {
        Point pt = points[j];
        if (pt.isEmpty()) {
          continue;
        }

        computeMinDistance3(line, pt, locGeom);
        if (minDistance <= _terminateDistance) {
          return;
        }
      }
    }
  }

  void computeMinDistance2(LineString line0, LineString line1, Array<GeometryLocation?> locGeom) {
    if (line0.getEnvelopeInternal().distance(line1.getEnvelopeInternal()) > minDistance) {
      return;
    }

    Array<Coordinate> coord0 = line0.getCoordinates();
    Array<Coordinate> coord1 = line1.getCoordinates();
    for (int i = 0; i < (coord0.length - 1); i++) {
      Envelope segEnv0 = Envelope.fromCoordinate(coord0[i], coord0[i + 1]);
      if (segEnv0.distance(line1.getEnvelopeInternal()) > minDistance) {
        continue;
      }

      for (int j = 0; j < (coord1.length - 1); j++) {
        Envelope segEnv1 = Envelope.fromCoordinate(coord1[j], coord1[j + 1]);
        if (segEnv0.distance(segEnv1) > minDistance) {
          continue;
        }

        double dist = Distance.segmentToSegment(coord0[i], coord0[i + 1], coord1[j], coord1[j + 1]);
        if (dist < minDistance) {
          minDistance = dist;
          LineSegment seg0 = LineSegment(coord0[i], coord0[i + 1]);
          LineSegment seg1 = LineSegment(coord1[j], coord1[j + 1]);
          Array<Coordinate> closestPt = seg0.closestPoints(seg1);
          locGeom[0] = GeometryLocation(line0, i, closestPt[0]);
          locGeom[1] = GeometryLocation(line1, j, closestPt[1]);
        }
        if (minDistance <= _terminateDistance) {
          return;
        }
      }
    }
  }

  void computeMinDistance3(LineString line, Point pt, Array<GeometryLocation?> locGeom) {
    if (line.getEnvelopeInternal().distance(pt.getEnvelopeInternal()) > minDistance) {
      return;
    }

    Array<Coordinate> coord0 = line.getCoordinates();
    Coordinate coord = pt.getCoordinate()!;
    for (int i = 0; i < (coord0.length - 1); i++) {
      double dist = Distance.pointToSegment(coord, coord0[i], coord0[i + 1]);
      if (dist < minDistance) {
        minDistance = dist;
        LineSegment seg = LineSegment(coord0[i], coord0[i + 1]);
        Coordinate segClosestPoint = seg.closestPoint(coord);
        locGeom[0] = GeometryLocation(line, i, segClosestPoint);
        locGeom[1] = GeometryLocation(pt, 0, coord);
      }
      if (minDistance <= _terminateDistance) {
        return;
      }
    }
  }
}
