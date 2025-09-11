import 'package:dts/src/jts/geom/point.dart';

import 'coordinate.dart';
import 'dimension.dart';
import 'geometry.dart';
import 'geometry_collection.dart';
import 'geometry_factory.dart';
import 'precision_model.dart';
import 'puntal.dart';

class MultiPoint extends GeometryCollection<Point> implements Puntal {
  MultiPoint.of(List<Point>? points, PrecisionModel pm, int srid) : this(points, GeometryFactory(pm: pm, srid: srid));

  MultiPoint(super.points, super.factory);

  @override
  int getDimension() => Dimension.P;

  @override
  bool hasDimension(int dim) => dim == Dimension.P;

  @override
  int getBoundaryDimension() => Dimension.kFalse;

  @override
  GeometryType get geometryType => GeometryType.multiPoint;

  @override
  Geometry getBoundary() => factory.createGeomCollection();

  @override
  MultiPoint reverse() => super.reverse() as MultiPoint;

  @override
  MultiPoint reverseInternal() {
    return MultiPoint(geometries.map((e) => e.copy()).toList(), factory);
  }

  @override
  bool equalsExact2(Geometry other, double tolerance) {
    if (!isEquivalentClass(other)) {
      return false;
    }
    return super.equalsExact2(other, tolerance);
  }

  Coordinate? getCoordinate2(int n) => geometries[n].getCoordinate();

  @override
  MultiPoint copyInternal() {
    return MultiPoint(geometries.toList(), factory);
  }
}
