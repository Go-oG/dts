import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/puntal.dart';

import 'cascaded_polygon_union.dart';
import 'input_extracter.dart';
import 'point_geometry_union.dart';
import 'union_strategy.dart';

class UnaryUnionOp {
  static Geometry? union2(List<Geometry> geoms) {
    UnaryUnionOp op = UnaryUnionOp(geoms);
    return op.union();
  }

  static Geometry? union3(List<Geometry> geoms, GeometryFactory geomFact) {
    UnaryUnionOp op = UnaryUnionOp(geoms, geomFact);
    return op.union();
  }

  static Geometry? union4(Geometry geom) {
    UnaryUnionOp op = UnaryUnionOp.of(geom);
    return op.union();
  }

  GeometryFactory? _geomFact;

  late InputExtracter _extracter;

  UnionStrategy _unionFunction = CascadedPolygonUnion.classicUnion;

  UnaryUnionOp(List<Geometry> geoms, [this._geomFact]) {
    extract(geoms);
  }

  UnaryUnionOp.of(Geometry geom) {
    extract2(geom);
  }

  void setUnionFunction(UnionStrategy unionFun) {
    _unionFunction = unionFun;
  }

  void extract(List<Geometry> geoms) {
    _extracter = InputExtracter.extract2(geoms);
  }

  void extract2(Geometry geom) {
    _extracter = InputExtracter.extract(geom);
  }

  Geometry? union() {
    _geomFact ??= _extracter.getFactory();

    if (_geomFact == null) {
      return null;
    }
    if (_extracter.isEmpty()) {
      return _geomFact!.createEmpty(_extracter.getDimension());
    }
    List<Geometry> points = _extracter.getExtract(0)!;
    List<Geometry> lines = _extracter.getExtract(1)!;
    List<Geometry> polygons = _extracter.getExtract(2)!;
    Geometry? unionPoints;
    if (points.isNotEmpty) {
      Geometry ptGeom = _geomFact!.buildGeometry(points);
      unionPoints = unionNoOpt(ptGeom);
    }
    Geometry? unionLines;
    if (lines.isNotEmpty) {
      Geometry lineGeom = _geomFact!.buildGeometry(lines);
      unionLines = unionNoOpt(lineGeom);
    }
    Geometry? unionPolygons;
    if (polygons.isNotEmpty) {
      unionPolygons = CascadedPolygonUnion.union3(polygons, _unionFunction);
    }
    Geometry? unionLA = unionWithNull(unionLines, unionPolygons);
    Geometry? union;
    if (unionPoints == null) {
      union = unionLA;
    } else if (unionLA == null) {
      union = unionPoints;
    } else {
      union = PointGeometryUnion.union2(unionPoints as Puntal, unionLA);
    }
    if (union == null) {
      return _geomFact!.createGeometryCollection();
    }

    return union;
  }

  Geometry? unionWithNull(Geometry? g0, Geometry? g1) {
    if ((g0 == null) && (g1 == null)) return null;

    if (g1 == null) return g0;

    if (g0 == null) return g1;

    return g0.union2(g1);
  }

  Geometry? unionNoOpt(Geometry g0) {
    Geometry empty = _geomFact!.createPoint();
    return _unionFunction.union(g0, empty);
  }
}
