import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/operation/overlayng/coverage_union.dart' as cu;

class CoverageUnion {
  static Geometry? union(List<Geometry> coverage) {
    if (coverage.isEmpty) {
      return null;
    }
    GeometryFactory geomFact = coverage[0].factory;
    GeometryCollection geoms = geomFact.createGeomCollection(coverage);
    return cu.CoverageUnionNG.union(geoms);
  }
}
