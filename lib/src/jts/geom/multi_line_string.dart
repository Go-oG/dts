 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/operation/boundary_op.dart';

import 'dimension.dart';
import 'geometry.dart';
import 'geometry_collection.dart';
import 'geometry_factory.dart';
import 'line_string.dart';
import 'lineal.dart';
import 'precision_model.dart';

class MultiLineString extends GeometryCollection<LineString> implements Lineal {
  MultiLineString.of(Array<LineString> lineStrings, PrecisionModel precisionModel, int srid)
    : super(lineStrings, GeometryFactory.of2(precisionModel, srid));

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
      return Dimension.FALSE;
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
  MultiLineString reverseInternal() {
    Array<LineString> lineStrings = Array(geometries.length);
    for (int i = 0; i < lineStrings.length; i++) {
      lineStrings[i] = ((geometries[i].reverse()));
    }
    return MultiLineString(lineStrings, factory);
  }

  @override
  MultiLineString copyInternal() {
    Array<LineString> lineStrings = Array(geometries.length);
    for (int i = 0; i < lineStrings.length; i++) {
      lineStrings[i] = (geometries[i].copy());
    }
    return MultiLineString(lineStrings, factory);
  }

  @override
  bool equalsExact2(Geometry other, double tolerance) {
    if (!isEquivalentClass(other)) {
      return false;
    }
    return super.equalsExact2(other, tolerance);
  }
}
