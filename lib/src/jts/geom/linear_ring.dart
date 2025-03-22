 import 'package:d_util/d_util.dart';

import 'coordinate.dart';
import 'coordinate_sequence.dart';
import 'dimension.dart';
import 'geometry.dart';
import 'geometry_factory.dart';
import 'line_string.dart';
import 'precision_model.dart';

class LinearRing extends LineString {
  static const int MINIMUM_VALID_SIZE = 3;

  LinearRing(Array<Coordinate>? points, PrecisionModel precisionModel, int SRID)
    : this.of(points, GeometryFactory.of2(precisionModel, SRID));

  LinearRing.of(Array<Coordinate>? points, GeometryFactory factory)
    : this.of2(factory.coordinateSequenceFactory.create(points), factory);

  LinearRing.of2(super.points, super.factory) : super.of() {
    validateConstruction();
  }

  void validateConstruction() {
    if ((!isEmpty()) && (!super.isClosed())) {
      throw IllegalArgumentException("Points of LinearRing do not form a closed linestring");
    }
    if ((getCoordinateSequence().size() >= 1) && (getCoordinateSequence().size() < MINIMUM_VALID_SIZE)) {
      throw IllegalArgumentException(
        "${("Invalid number of points in LinearRing (found ${getCoordinateSequence().size()} - must be 0 or >= $MINIMUM_VALID_SIZE")})",
      );
    }
  }

  @override
  int getBoundaryDimension() {
    return Dimension.FALSE;
  }

  @override
  bool isClosed() {
    if (isEmpty()) {
      return true;
    }
    return super.isClosed();
  }

  @override
  GeometryType get geometryType {
    return GeometryType.linearRing;
  }

  @override
  LinearRing copyInternal() {
    return LinearRing.of2(points.copy(), factory);
  }

  @override
  LinearRing reverse() {
    return (super.reverse() as LinearRing);
  }

  @override
  LinearRing reverseInternal() {
    CoordinateSequence seq = points.copy();
    CoordinateSequences.reverse(seq);
    return factory.createLinearRing3(seq);
  }
}
