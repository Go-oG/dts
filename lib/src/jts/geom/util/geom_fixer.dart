import '../../operation/buffer/buffer_op.dart';
import '../../operation/overlay/overlay_op.dart';
import '../../operation/overlayng/overlay_ngrobust.dart';
import '../coordinate.dart';
import '../coordinate_arrays.dart';
import '../geometry.dart';
import '../geometry_collection.dart';
import '../geometry_factory.dart';
import '../line_string.dart';
import '../linear_ring.dart';
import '../multi_line_string.dart';
import '../multi_point.dart';
import '../multi_polygon.dart';
import '../point.dart';
import '../polygon.dart';
import '../prep/prepared_geometry.dart';

class GeometryFixer {
  static final bool _defaultKeepMulti = true;

  static Geometry fix(Geometry geom, [bool isKeepMulti = true]) {
    GeometryFixer fix = GeometryFixer(geom);
    fix.setKeepMulti(isKeepMulti);
    return fix.getResult();
  }

  Geometry geom;

  late GeometryFactory factory;

  bool _isKeepCollapsed = false;

  bool _isKeepMulti = _defaultKeepMulti;

  GeometryFixer(this.geom) {
    factory = geom.factory;
  }

  void setKeepCollapsed(bool isKeepCollapsed) {
    _isKeepCollapsed = isKeepCollapsed;
  }

  void setKeepMulti(bool isKeepMulti) {
    _isKeepMulti = isKeepMulti;
  }

  Geometry getResult() {
    final geom = this.geom;
    if (geom.getNumGeometries() == 0) {
      return geom.copy();
    }
    if (geom is Point) {
      return fixPoint(geom);
    }

    if (geom is LinearRing) return fixLinearRing(geom);

    if (geom is LineString) return fixLineString(geom);

    if (geom is Polygon) return fixPolygon(geom);

    if (geom is MultiPoint) return fixMultiPoint(geom);

    if (geom is MultiLineString) return fixMultiLineString(geom);

    if (geom is MultiPolygon) return fixMultiPolygon(geom);

    if (geom is GeometryCollection) return fixCollection(geom);

    throw "UnsupportedOperationException${geom.runtimeType}";
  }

  Point fixPoint(Point geom) {
    final pt = fixPointElement(geom);
    if (pt == null) return factory.createPoint();
    return (pt);
  }

  Point? fixPointElement(Point geom) {
    if (geom.isEmpty() || (!isValidPoint(geom))) {
      return null;
    }
    return geom.copy();
  }

  static bool isValidPoint(Point pt) {
    final p = pt.getCoordinate()!;
    return p.isValid();
  }

  Geometry fixMultiPoint(MultiPoint geom) {
    List<Point> pts = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Point pt = geom.getGeometryN(i);
      if (pt.isEmpty()) continue;

      final fixPt = fixPointElement(pt);
      if (fixPt != null) {
        pts.add(fixPt);
      }
    }
    if (!_isKeepMulti && pts.length == 1) return pts.first;
    return factory.createMultiPoint(pts);
  }

  Geometry fixLinearRing(LinearRing geom) {
    Geometry? fix = fixLinearRingElement(geom);
    if (fix == null) {
      return factory.createLinearRing();
    }

    return fix;
  }

  Geometry? fixLinearRingElement(LinearRing geom) {
    if (geom.isEmpty()) return null;

    final pts = geom.getCoordinates();
    final ptsFix = fixCoordinates(pts);
    if (_isKeepCollapsed) {
      if (ptsFix.length == 1) {
        return factory.createPoint2(ptsFix[0]);
      }
      if ((ptsFix.length > 1) && (ptsFix.length <= 3)) {
        return factory.createLineString2(ptsFix);
      }
    }
    if (ptsFix.length <= 3) {
      return null;
    }
    LinearRing ring = factory.createLinearRings(ptsFix);
    if (!ring.isValid()) {
      return factory.createLineString2(ptsFix);
    }
    return ring;
  }

  Geometry fixLineString(LineString geom) {
    final fix = fixLineStringElement(geom);
    if (fix == null) {
      return factory.createLineString();
    }
    return fix;
  }

  Geometry? fixLineStringElement(LineString geom) {
    if (geom.isEmpty()) return null;

    final pts = geom.getCoordinates();
    final ptsFix = fixCoordinates(pts);
    if (_isKeepCollapsed && (ptsFix.length == 1)) {
      return factory.createPoint2(ptsFix[0]);
    }
    if (ptsFix.length <= 1) {
      return null;
    }
    return factory.createLineString2(ptsFix);
  }

  static List<Coordinate> fixCoordinates(List<Coordinate> pts) {
    final ptsClean = CoordinateArrays.removeRepeatedOrInvalidPoints(pts);
    return CoordinateArrays.copyDeep(ptsClean);
  }

  Geometry fixMultiLineString(MultiLineString geom) {
    List<Geometry> fixed = [];
    bool isMixed = false;
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      LineString line = geom.getGeometryN(i);
      if (line.isEmpty()) continue;

      Geometry? fix = fixLineStringElement(line);
      if (fix == null) continue;

      if (fix is! LineString) {
        isMixed = true;
      }
      fixed.add(fix);
    }
    if (fixed.length == 1) {
      if ((!_isKeepMulti) || (fixed.first is! LineString)) return fixed.first;
    }
    if (isMixed) {
      return factory.createGeomCollection(fixed);
    }
    return factory.createMultiLineString(fixed.cast());
  }

  Geometry fixPolygon(Polygon geom) {
    final fix = fixPolygonElement(geom);
    if (fix == null) {
      return factory.createPolygon();
    }

    return fix;
  }

  Geometry? fixPolygonElement(Polygon geom) {
    LinearRing shell = geom.getExteriorRing();
    Geometry fixShell = fixRing(shell)!;
    if (fixShell.isEmpty()) {
      if (_isKeepCollapsed) {
        return fixLineString(shell);
      }
      return null;
    }
    if (geom.getNumInteriorRing() == 0) {
      return fixShell;
    }
    List<Geometry> holesFixed = fixHoles(geom);
    List<Geometry> holes = [];
    List<Geometry> shells = [];
    classifyHoles(fixShell, holesFixed, holes, shells);
    Geometry polyWithHoles = difference(fixShell, holes);
    if (shells.isEmpty) {
      return polyWithHoles;
    }
    shells.add(polyWithHoles);
    return union(shells);
  }

  List<Geometry> fixHoles(Polygon geom) {
    List<Geometry> holes = [];
    for (int i = 0; i < geom.getNumInteriorRing(); i++) {
      final holeRep = fixRing(geom.getInteriorRingN(i));
      if (holeRep != null) {
        holes.add(holeRep);
      }
    }
    return holes;
  }

  void classifyHoles(Geometry shell, List<Geometry> holesFixed,
      List<Geometry> holes, List<Geometry> shells) {
    PreparedGeom shellPrep = PreparedGeomFactory.prepare(shell);
    for (Geometry hole in holesFixed) {
      if (shellPrep.intersects(hole)) {
        holes.add(hole);
      } else {
        shells.add(hole);
      }
    }
  }

  Geometry difference(Geometry shell, List<Geometry>? holes) {
    if (holes == null || holes.isEmpty) {
      return shell;
    }

    Geometry? holesUnion = union(holes);
    return OverlayNGRobust.overlay(
        shell, holesUnion!, OverlayOpCode.difference);
  }

  Geometry? union(List<Geometry> polys) {
    if (polys.isEmpty) {
      return factory.createPolygon();
    }

    if (polys.length == 1) {
      return polys.first;
    }
    return OverlayNGRobust.union2(polys);
  }

  Geometry? fixRing(LinearRing ring) {
    Geometry poly = factory.createPolygon(ring);
    return BufferOp.bufferByZero(poly, true);
  }

  Geometry fixMultiPolygon(MultiPolygon geom) {
    List<Geometry> polys = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Polygon poly = geom.getGeometryN(i);
      final polyFix = fixPolygonElement(poly);
      if ((polyFix != null) && (!polyFix.isEmpty())) {
        polys.add(polyFix);
      }
    }
    if (polys.isEmpty) {
      return factory.createMultiPolygon();
    }
    Geometry result = union(polys)!;
    if (_isKeepMulti && (result is Polygon)) {
      result = factory.createMultiPolygon([result]);
    }

    return result;
  }

  Geometry fixCollection(GeometryCollection geom) {
    List<Geometry> geomRep = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      geomRep.add(fix3(geom.getGeometryN(i), _isKeepCollapsed, _isKeepMulti));
    }
    return factory.createGeomCollection(geomRep);
  }

  static Geometry fix3(Geometry geom, bool isKeepCollapsed, bool isKeepMulti) {
    GeometryFixer fix = GeometryFixer(geom);
    fix.setKeepCollapsed(isKeepCollapsed);
    fix.setKeepMulti(isKeepMulti);
    return fix.getResult();
  }
}
