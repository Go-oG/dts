import '../geometry.dart';
import '../geometry_factory.dart';

class GeometryCombiner {
  static Geometry? combine2(List<Geometry> geoms) {
    GeometryCombiner combiner = GeometryCombiner(geoms);
    return combiner.combine();
  }

  static Geometry? combine3(Geometry g0, Geometry g1) {
    GeometryCombiner combiner = GeometryCombiner([g0, g1]);
    return combiner.combine();
  }

  static Geometry? combine4(Geometry g0, Geometry g1, Geometry g2) {
    GeometryCombiner combiner = GeometryCombiner([g0, g1, g2]);
    return combiner.combine();
  }

  GeometryFactory? geomFactory;

  final bool _skipEmpty = false;

  final List<Geometry> _inputGeoms;

  GeometryCombiner(this._inputGeoms) {
    geomFactory = extractFactory(_inputGeoms);
  }

  static GeometryFactory? extractFactory(List<Geometry> geoms) {
    if (geoms.isEmpty) return null;
    return geoms.first.factory;
  }

  Geometry? combine() {
    List<Geometry> elems = [];
    for (var g in _inputGeoms) {
      extractElements(g, elems);
    }
    if (elems.isEmpty) {
      if (geomFactory != null) {
        return geomFactory!.createGeometryCollection();
      }
      return null;
    }
    return geomFactory!.buildGeometry(elems);
  }

  void extractElements(Geometry? geom, List<Geometry> elems) {
    if (geom == null) return;

    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry elemGeom = geom.getGeometryN(i);
      if (_skipEmpty && elemGeom.isEmpty()) continue;
      elems.add(elemGeom);
    }
  }
}
