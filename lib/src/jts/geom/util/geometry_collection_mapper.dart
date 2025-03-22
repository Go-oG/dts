import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';

import 'geometry_mapper.dart';

class GeometryCollectionMapper {
  static GeometryCollection map2(GeometryCollection gc, MapOp op) {
    GeometryCollectionMapper mapper = GeometryCollectionMapper(op);
    return mapper.map(gc);
  }

  final MapOp _mapOp;

  GeometryCollectionMapper(this._mapOp);

  GeometryCollection map(GeometryCollection gc) {
    List<Geometry> mapped = [];
    for (int i = 0; i < gc.getNumGeometries(); i++) {
      Geometry? g = _mapOp.map(gc.getGeometryN(i));
      if (g != null && !g.isEmpty()) {
        mapped.add(g);
      }
    }
    return gc.factory.createGeometryCollection2(GeometryFactory.toGeometryArray(mapped)!);
  }
}
