import 'dimension.dart';
import 'geometry.dart';
import 'geometry_collection.dart';
import 'geometry_factory.dart';
import 'line_string.dart';
import 'polygon.dart';
import 'polygonal.dart';
import 'precision_model.dart';

class MultiPolygon extends GeometryCollection<Polygon> implements Polygonal {
  MultiPolygon(List<Polygon>? polygons, PrecisionModel pm, int srid)
      : this.of(polygons, GeometryFactory(pm: pm, srid: srid));

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
  GeometryType get geometryType {
    return GeometryType.multiPolygon;
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
    return factory.createMultiLineString(allRings);
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
    return MultiPolygon.of(
        geometries.map((e) => e.reverse()).toList(), factory);
  }

  @override
  MultiPolygon copyInternal() {
    return MultiPolygon.of(geometries.map((e) => e.copy()).toList(), factory);
  }
}
