import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/point.dart';

import 'coordinate.dart';
import 'dimension.dart';
import 'geometry.dart';
import 'geometry_collection.dart';
import 'geometry_factory.dart';
import 'precision_model.dart';
import 'puntal.dart';

class MultiPoint extends GeometryCollection<Point> implements Puntal {
  MultiPoint.of(Array<Point>? points, PrecisionModel pm, int SRID)
      : this(points, GeometryFactory(pm: pm, srid: SRID));

  MultiPoint(super.points, super.factory);

  @override
  int getDimension() {
    return Dimension.P;
  }

  @override
  bool hasDimension(int dim) {
    return dim == Dimension.P;
  }

  @override
  int getBoundaryDimension() {
    return Dimension.False;
  }

  @override
  GeometryType get geometryType {
    return GeometryType.multiPoint;
  }

  @override
  Geometry getBoundary() {
    return factory.createGeomCollection();
  }

  @override
  MultiPoint reverse() {
    return super.reverse() as MultiPoint;
  }

  @override
  MultiPoint reverseInternal() {
    Array<Point> points = Array(geometries.length);
    for (int i = 0; i < points.length; i++) {
      points[i] = (geometries[i].copy());
    }
    return MultiPoint(points, factory);
  }

  @override
  bool equalsExact2(Geometry other, double tolerance) {
    if (!isEquivalentClass(other)) {
      return false;
    }
    return super.equalsExact2(other, tolerance);
  }

  Coordinate? getCoordinate2(int n) {
    return geometries[n].getCoordinate();
  }

  @override
  MultiPoint copyInternal() {
    Array<Point> points = Array(geometries.length);
    for (int i = 0; i < points.length; i++) {
      points[i] = geometries[i];
    }
    return MultiPoint(points, factory);
  }
}
