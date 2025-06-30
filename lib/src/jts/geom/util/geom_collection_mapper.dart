import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_collection.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';

import 'geometry_mapper.dart';

class GeomCollectionMapper {
  static GeomCollection map2(GeomCollection gc, MapOp op) {
    GeomCollectionMapper mapper = GeomCollectionMapper(op);
    return mapper.map(gc);
  }

  final MapOp _mapOp;

  GeomCollectionMapper(this._mapOp);

  GeomCollection map(GeomCollection gc) {
    List<Geometry> mapped = [];
    for (int i = 0; i < gc.getNumGeometries(); i++) {
      Geometry? g = _mapOp.map(gc.getGeometryN(i));
      if (g != null && !g.isEmpty()) {
        mapped.add(g);
      }
    }
    return gc.factory.createGeomCollection(GeomFactory.toGeometryArray(mapped)!);
  }
}
