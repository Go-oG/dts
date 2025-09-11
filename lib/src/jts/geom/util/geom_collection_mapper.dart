import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';

import 'geometry_mapper.dart';

class GeomCollectionMapper {
  static GeometryCollection map2(GeometryCollection gc, MapOp op) {
    GeomCollectionMapper mapper = GeomCollectionMapper(op);
    return mapper.map(gc);
  }

  final MapOp _mapOp;

  GeomCollectionMapper(this._mapOp);

  GeometryCollection map(GeometryCollection gc) {
    List<Geometry> mapped = [];
    for (int i = 0; i < gc.getNumGeometries(); i++) {
      Geometry? g = _mapOp.map(gc.getGeometryN(i));
      if (g != null && !g.isEmpty()) {
        mapped.add(g);
      }
    }
    return gc.factory.createGeomCollection(mapped);
  }
}
