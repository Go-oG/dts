import 'package:d_util/d_util.dart';

import 'dimension.dart';
import 'geom.dart';
import 'geom_collection.dart';
import 'geom_factory.dart';
import 'line_string.dart';
import 'polygon.dart';
import 'polygonal.dart';
import 'precision_model.dart';

class MultiPolygon extends GeomCollection<Polygon> implements Polygonal {
  MultiPolygon(Array<Polygon>? polygons, PrecisionModel pm, int srid)
      : this.of(polygons, GeomFactory(pm: pm, srid: srid));

  MultiPolygon.of(super.polygons, super.factory);

  @override
  int getDimension() {
    return Dimension.A;
  }

  @override
  bool hasDimension(int dim) {
    return dim == Dimension.A;
  }

  @override
  int getBoundaryDimension() {
    return Dimension.L;
  }

  @override
  GeomType get geometryType {
    return GeomType.multiPolygon;
  }

  @override
  Geometry getBoundary() {
    if (isEmpty()) {
      return factory.createMultiLineString();
    }
    List<LineString> allRings = [];
    for (int i = 0; i < geometries.length; i++) {
      Polygon polygon = ((geometries[i]));
      Geometry rings = polygon.getBoundary();
      for (int j = 0; j < rings.getNumGeometries(); j++) {
        allRings.add(rings.getGeometryN(j) as LineString);
      }
    }
    return factory.createMultiLineString(allRings.toArray());
  }

  @override
  bool equalsExact2(Geometry other, double tolerance) {
    if (!isEquivalentClass(other)) {
      return false;
    }
    return super.equalsExact2(other, tolerance);
  }

  @override
  MultiPolygon reverse() {
    return (super.reverse() as MultiPolygon);
  }

  @override
  MultiPolygon reverseInternal() {
    Array<Polygon> polygons = Array(geometries.length);
    for (int i = 0; i < polygons.length; i++) {
      polygons[i] = geometries[i].reverse();
    }
    return MultiPolygon.of(polygons, factory);
  }

  @override
  MultiPolygon copyInternal() {
    Array<Polygon> polygons = Array(geometries.length);
    for (int i = 0; i < polygons.length; i++) {
      polygons[i] = geometries[i].copy();
    }
    return MultiPolygon.of(polygons, factory);
  }
}
