import 'package:dts/src/jts/operation/boundary_op.dart';

import 'dimension.dart';
import 'geometry.dart';
import 'geometry_collection.dart';
import 'geometry_factory.dart';
import 'line_string.dart';
import 'lineal.dart';
import 'precision_model.dart';

class MultiLineString extends GeometryCollection<LineString> implements Lineal {
  MultiLineString.of(List<LineString> lineStrings, PrecisionModel precisionModel, int srid)
      : super(lineStrings, GeometryFactory(pm: precisionModel, srid: srid));

  MultiLineString(super.lineStrings, super.factory);

  @override
  int getDimension() {
    return Dimension.L;
  }

  @override
  bool hasDimension(int dim) {
    return dim == Dimension.L;
  }

  @override
  int getBoundaryDimension() {
    if (isClosed()) {
      return Dimension.kFalse;
    }
    return Dimension.P;
  }

  @override
  GeometryType get geometryType {
    return GeometryType.multiLineString;
  }

  bool isClosed() {
    if (isEmpty()) {
      return false;
    }
    for (int i = 0; i < geometries.length; i++) {
      if (!(geometries[i]).isClosed()) {
        return false;
      }
    }
    return true;
  }

  @override
  Geometry? getBoundary() {
    return BoundaryOp(this).getBoundary();
  }

  @override
  MultiLineString reverse() {
    return (super.reverse() as MultiLineString);
  }

  @override
  MultiLineString reverseInternal() => MultiLineString(geometries.map((e) => e.reverse()).toList(), factory);

  @override
  MultiLineString copyInternal() => MultiLineString(geometries.map((e) => e.copy()).toList(), factory);

  @override
  bool equalsExact2(Geometry other, double tolerance) {
    if (!isEquivalentClass(other)) {
      return false;
    }
    return super.equalsExact2(other, tolerance);
  }
}
