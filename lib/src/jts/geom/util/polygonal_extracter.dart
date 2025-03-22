import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/polygon.dart';

class PolygonalExtracter {
  static List<Geometry> getPolygonals2(Geometry geom, List<Geometry> list) {
    if ((geom is Polygon) || (geom is MultiPolygon)) {
      list.add(geom);
    } else if (geom is GeometryCollection) {
      for (int i = 0; i < geom.getNumGeometries(); i++) {
        getPolygonals2(geom.getGeometryN(i), list);
      }
    }
    return list;
  }

  static List<Geometry> getPolygonals(Geometry geom) {
    return getPolygonals2(geom, []);
  }
}
