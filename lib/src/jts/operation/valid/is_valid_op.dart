import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_point.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'indexed_nested_hole_tester.dart';
import 'indexed_nested_polygon_tester.dart';
import 'polygon_topology_analyzer.dart';
import 'topology_validation_error.dart';

final class IsValidOp {
  static const int _minSizeLineString = 2;

  static const int _minSizeRing = 4;

  static bool isValid3(Geometry geom) {
    IsValidOp isValidOp = IsValidOp(geom);
    return isValidOp.isValid();
  }

  static bool isValid2(Coordinate coord) {
    if (Double.isNaN(coord.x)) return false;

    if (Double.isInfinite(coord.x)) return false;

    if (Double.isNaN(coord.y)) return false;

    if (Double.isInfinite(coord.y)) return false;

    return true;
  }

  final Geometry inputGeometry;
  bool _isInvertedRingValid = false;

  TopologyValidationError? _validErr;

  IsValidOp(this.inputGeometry);

  void setSelfTouchingRingFormingHoleValid(bool isValid) {
    _isInvertedRingValid = isValid;
  }

  bool isValid() {
    return isValidGeometry(inputGeometry);
  }

  TopologyValidationError getValidationError() {
    isValidGeometry(inputGeometry);
    return _validErr!;
  }

  void logInvalid(int code, Coordinate? pt) {
    _validErr = TopologyValidationError(code, pt);
  }

  bool hasInvalidError() {
    return _validErr != null;
  }

  bool isValidGeometry(Geometry g) {
    _validErr = null;
    if (g.isEmpty()) return true;

    if (g is Point) return isValid9(g);

    if (g is MultiPoint) return isValid7(g);

    if (g is LinearRing) return isValid5(g);

    if (g is LineString) return isValid6(g);

    if (g is Polygon) return isValid10(g);

    if (g is MultiPolygon) return isValid8(g);

    if (g is GeometryCollection) return isValid4(g);

    throw "UnsupportedOperationException${g.runtimeType}";
  }

  bool isValid9(Point g) {
    checkCoordinatesValid2(g.getCoordinates());
    if (hasInvalidError()) return false;

    return true;
  }

  bool isValid7(MultiPoint g) {
    checkCoordinatesValid2(g.getCoordinates());
    if (hasInvalidError()) return false;

    return true;
  }

  bool isValid6(LineString g) {
    checkCoordinatesValid2(g.getCoordinates());
    if (hasInvalidError()) return false;

    checkPointSize(g, _minSizeLineString);
    if (hasInvalidError()) return false;

    return true;
  }

  bool isValid5(LinearRing g) {
    checkCoordinatesValid2(g.getCoordinates());
    if (hasInvalidError()) return false;

    checkRingClosed(g);
    if (hasInvalidError()) return false;

    checkRingPointSize(g);
    if (hasInvalidError()) return false;

    checkRingSimple(g);
    return _validErr == null;
  }

  bool isValid10(Polygon g) {
    checkCoordinatesValid(g);
    if (hasInvalidError()) return false;

    checkRingsClosed(g);
    if (hasInvalidError()) return false;

    checkRingsPointSize(g);
    if (hasInvalidError()) return false;

    final areaAnalyzer = PolygonTopologyAnalyzer(g, _isInvertedRingValid);
    checkAreaIntersections(areaAnalyzer);
    if (hasInvalidError()) return false;

    checkHolesInShell(g);
    if (hasInvalidError()) return false;

    checkHolesNotNested(g);
    if (hasInvalidError()) return false;

    checkInteriorConnected(areaAnalyzer);
    if (hasInvalidError()) return false;

    return true;
  }

  bool isValid8(MultiPolygon g) {
    for (int i = 0; i < g.getNumGeometries(); i++) {
      Polygon p = g.getGeometryN(i);
      checkCoordinatesValid(p);
      if (hasInvalidError()) return false;

      checkRingsClosed(p);
      if (hasInvalidError()) return false;

      checkRingsPointSize(p);
      if (hasInvalidError()) return false;
    }
    PolygonTopologyAnalyzer areaAnalyzer = PolygonTopologyAnalyzer(g, _isInvertedRingValid);
    checkAreaIntersections(areaAnalyzer);
    if (hasInvalidError()) return false;

    for (int i = 0; i < g.getNumGeometries(); i++) {
      Polygon p = g.getGeometryN(i);
      checkHolesInShell(p);
      if (hasInvalidError()) return false;
    }
    for (int i = 0; i < g.getNumGeometries(); i++) {
      Polygon p = g.getGeometryN(i);
      checkHolesNotNested(p);
      if (hasInvalidError()) return false;
    }
    checkShellsNotNested(g);
    if (hasInvalidError()) return false;

    checkInteriorConnected(areaAnalyzer);
    if (hasInvalidError()) return false;

    return true;
  }

  bool isValid4(GeometryCollection gc) {
    for (int i = 0; i < gc.getNumGeometries(); i++) {
      if (!isValidGeometry(gc.getGeometryN(i))) return false;
    }
    return true;
  }

  void checkCoordinatesValid2(Array<Coordinate> coords) {
    for (var i in coords) {
      if (!isValid2(i)) {
        logInvalid(TopologyValidationError.INVALID_COORDINATE, i);
        return;
      }
    }
  }

  void checkCoordinatesValid(Polygon poly) {
    checkCoordinatesValid2(poly.getExteriorRing().getCoordinates());
    if (hasInvalidError()) return;

    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      checkCoordinatesValid2(poly.getInteriorRingN(i).getCoordinates());
      if (hasInvalidError()) return;
    }
  }

  void checkRingClosed(LinearRing ring) {
    if (ring.isEmpty()) return;
    if (!ring.isClosed()) {
      Coordinate? pt = (ring.getNumPoints() >= 1) ? ring.getCoordinateN(0) : null;
      logInvalid(TopologyValidationError.RING_NOT_CLOSED, pt);
      return;
    }
  }

  void checkRingsClosed(Polygon poly) {
    checkRingClosed(poly.getExteriorRing());
    if (hasInvalidError()) return;

    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      checkRingClosed(poly.getInteriorRingN(i));
      if (hasInvalidError()) return;
    }
  }

  void checkRingsPointSize(Polygon poly) {
    checkRingPointSize(poly.getExteriorRing());
    if (hasInvalidError()) return;

    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      checkRingPointSize(poly.getInteriorRingN(i));
      if (hasInvalidError()) return;
    }
  }

  void checkRingPointSize(LinearRing ring) {
    if (ring.isEmpty()) return;

    checkPointSize(ring, _minSizeRing);
  }

  void checkPointSize(LineString line, int minSize) {
    if (!isNonRepeatedSizeAtLeast(line, minSize)) {
      Coordinate? pt = (line.getNumPoints() >= 1) ? line.getCoordinateN(0) : null;
      logInvalid(TopologyValidationError.TOO_FEW_POINTS, pt);
    }
  }

  bool isNonRepeatedSizeAtLeast(LineString line, int minSize) {
    int numPts = 0;
    Coordinate? prevPt;
    for (int i = 0; i < line.getNumPoints(); i++) {
      if (numPts >= minSize) return true;
      final pt = line.getCoordinateN(i);
      if ((prevPt == null) || (!pt.equals2D(prevPt))) numPts++;

      prevPt = pt;
    }
    return numPts >= minSize;
  }

  void checkAreaIntersections(PolygonTopologyAnalyzer areaAnalyzer) {
    if (areaAnalyzer.hasInvalidIntersection()) {
      logInvalid(areaAnalyzer.getInvalidCode(), areaAnalyzer.getInvalidLocation());
      return;
    }
  }

  void checkRingSimple(LinearRing ring) {
    Coordinate? intPt = PolygonTopologyAnalyzer.findSelfIntersection(ring);
    if (intPt != null) {
      logInvalid(TopologyValidationError.RING_SELF_INTERSECTION, intPt);
    }
  }

  void checkHolesInShell(Polygon poly) {
    if (poly.getNumInteriorRing() <= 0) return;

    LinearRing shell = poly.getExteriorRing();
    bool isShellEmpty = shell.isEmpty();
    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      LinearRing hole = poly.getInteriorRingN(i);
      if (hole.isEmpty()) continue;

      Coordinate? invalidPt;
      if (isShellEmpty) {
        invalidPt = hole.getCoordinate();
      } else {
        invalidPt = findHoleOutsideShellPoint(hole, shell);
      }
      if (invalidPt != null) {
        logInvalid(TopologyValidationError.HOLE_OUTSIDE_SHELL, invalidPt);
        return;
      }
    }
  }

  Coordinate? findHoleOutsideShellPoint(LinearRing hole, LinearRing shell) {
    Coordinate holePt0 = hole.getCoordinateN(0);
    if (!shell.getEnvelopeInternal().covers(hole.getEnvelopeInternal())) return holePt0;

    if (PolygonTopologyAnalyzer.isRingNested(hole, shell)) return null;

    return holePt0;
  }

  void checkHolesNotNested(Polygon poly) {
    if (poly.getNumInteriorRing() <= 0) return;

    final nestedTester = IndexedNestedHoleTester(poly);
    if (nestedTester.isNested()) {
      logInvalid(TopologyValidationError.NESTED_HOLES, nestedTester.getNestedPoint());
    }
  }

  void checkShellsNotNested(MultiPolygon mp) {
    if (mp.getNumGeometries() <= 1) return;

    final nestedTester = IndexedNestedPolygonTester(mp);
    if (nestedTester.isNested()) {
      logInvalid(TopologyValidationError.NESTED_SHELLS, nestedTester.getNestedPoint());
    }
  }

  void checkInteriorConnected(PolygonTopologyAnalyzer analyzer) {
    if (analyzer.isInteriorDisconnected()) {
      logInvalid(
          TopologyValidationError.DISCONNECTED_INTERIOR, analyzer.getDisconnectionLocation());
    }
  }
}
