import 'package:d_util/d_util.dart';

import '../geometry.dart';
import '../geometry_collection.dart';

class GeometryMapper {
  static Geometry map(Geometry geom, MapOp op) {
    List<Geometry> mapped = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry? g = op.map(geom.getGeometryN(i));
      if (g != null) {
        mapped.add(g);
      }
    }
    return geom.factory.buildGeometry(mapped);
  }

  static List<Geometry> map2(List<Geometry> geoms, MapOp op) {
    List<Geometry> mapped = [];
    for (var g in geoms) {
      final gr = op.map(g);
      if (gr != null) {
        mapped.add(gr);
      }
    }
    return mapped;
  }

  static Geometry flatMap(Geometry geom, int emptyDim, MapOp op) {
    List<Geometry> mapped = [];
    flatMap2(geom, op, mapped);
    if (mapped.size == 0) {
      return geom.factory.createEmpty(emptyDim);
    }
    if (mapped.size == 1) {
      return mapped.get(0);
    }

    return geom.factory.buildGeometry(mapped);
  }

  static void flatMap2(Geometry geom, MapOp op, List<Geometry> mapped) {
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry g = geom.getGeometryN(i);
      if (g is GeometryCollection) {
        flatMap2(g, op, mapped);
      } else {
        final res = op.map(g);
        if ((res != null) && (!res.isEmpty())) {
          addFlat(res, mapped);
        }
      }
    }
  }

  static void addFlat(Geometry geom, List<Geometry> geomList) {
    if (geom.isEmpty()) {
      return;
    }

    if (geom is GeometryCollection) {
      for (int i = 0; i < geom.getNumGeometries(); i++) {
        addFlat(geom.getGeometryN(i), geomList);
      }
    } else {
      geomList.add(geom);
    }
  }
}

abstract interface class MapOp {
  Geometry? map(Geometry geom);
}

class MapOpNormal implements MapOp {
  final Geometry? Function(Geometry geom) mapFun;

  MapOpNormal(this.mapFun);

  @override
  Geometry? map(Geometry geom) {
    return mapFun(geom);
  }
}
