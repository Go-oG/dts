import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/index/spatial_index.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';

import 'polygon_topology_analyzer.dart';

final class IndexedNestedPolygonTester {
  final MultiPolygon multiPoly;
  late final SpatialIndex<int> index;
  Array<IndexedPointInAreaLocator>? locators;
  Coordinate? nestedPt;

  IndexedNestedPolygonTester(this.multiPoly) {
    index = STRtree();
    for (int i = 0; i < multiPoly.getNumGeometries(); i++) {
      Polygon poly = multiPoly.getGeometryN(i);
      Envelope env = poly.getEnvelopeInternal();
      index.insert(env, i);
    }
  }

  IndexedPointInAreaLocator getLocator(int polyIndex) {
    locators ??= Array(multiPoly.getNumGeometries());
    IndexedPointInAreaLocator? locator = locators!.get(polyIndex);
    if (locator == null) {
      locator = IndexedPointInAreaLocator(multiPoly.getGeometryN(polyIndex));
      locators![polyIndex] = locator;
    }
    return locator;
  }

  Coordinate? getNestedPoint() {
    return nestedPt;
  }

  bool isNested() {
    for (int i = 0; i < multiPoly.getNumGeometries(); i++) {
      Polygon poly = multiPoly.getGeometryN(i);
      LinearRing shell = poly.getExteriorRing();
      List<int> results = index.query(poly.getEnvelopeInternal());
      for (int polyIndex in results) {
        Polygon possibleOuterPoly = multiPoly.getGeometryN(polyIndex);
        if (poly == possibleOuterPoly) continue;

        if (!possibleOuterPoly
            .getEnvelopeInternal()
            .covers(poly.getEnvelopeInternal())) {
          continue;
        }

        nestedPt =
            findNestedPoint(shell, possibleOuterPoly, getLocator(polyIndex));
        if (nestedPt != null) return true;
      }
    }
    return false;
  }

  Coordinate? findNestedPoint(LinearRing shell, Polygon possibleOuterPoly,
      IndexedPointInAreaLocator locator) {
    Coordinate shellPt0 = shell.getCoordinateN(0);
    int loc0 = locator.locate(shellPt0);
    if (loc0 == Location.exterior) return null;

    if (loc0 == Location.interior) {
      return shellPt0;
    }
    Coordinate shellPt1 = shell.getCoordinateN(1);
    int loc1 = locator.locate(shellPt1);
    if (loc1 == Location.exterior) return null;

    if (loc1 == Location.interior) {
      return shellPt1;
    }
    return findIncidentSegmentNestedPoint(shell, possibleOuterPoly);
  }

  static Coordinate? findIncidentSegmentNestedPoint(
      LinearRing shell, Polygon poly) {
    LinearRing polyShell = poly.getExteriorRing();
    if (polyShell.isEmpty()) return null;

    if (!PolygonTopologyAnalyzer.isRingNested(shell, polyShell)) return null;

    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      LinearRing hole = poly.getInteriorRingN(i);
      if (hole.getEnvelopeInternal().covers(shell.getEnvelopeInternal()) &&
          PolygonTopologyAnalyzer.isRingNested(shell, hole)) {
        return null;
      }
    }
    return shell.getCoordinateN(0);
  }
}
