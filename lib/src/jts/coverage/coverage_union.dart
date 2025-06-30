import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_collection.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/operation/overlayng/coverage_union.dart' as cu;

class CoverageUnion {
  static Geometry? union(Array<Geometry> coverage) {
    if (coverage.isEmpty) {
      return null;
    }
    GeomFactory geomFact = coverage[0].factory;
    GeomCollection geoms = geomFact.createGeomCollection(coverage);
    return cu.CoverageUnionNG.union(geoms);
  }
}
