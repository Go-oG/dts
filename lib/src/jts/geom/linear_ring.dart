import 'coordinate.dart';
import 'coordinate_sequence.dart';
import 'dimension.dart';
import 'geometry.dart';
import 'geometry_factory.dart';
import 'line_string.dart';
import 'precision_model.dart';

class LinearRing extends LineString {
  static const int kMinValidSize = 3;

  LinearRing(List<Coordinate>? points, PrecisionModel precisionModel, int srid)
      : this.of(points, GeometryFactory(pm: precisionModel, srid: srid));

  LinearRing.of(List<Coordinate>? points, GeometryFactory factory)
      : this.of2(factory.csFactory.create(points), factory);

  LinearRing.of2(super.points, super.factory) : super.of() {
    validateConstruction();
  }

  void validateConstruction() {
    if (!isEmpty() && !super.isClosed()) {
      throw ArgumentError("Points of LinearRing do not form a closed linestring");
    }
    if ((getCoordinateSequence().size() >= 1) && (getCoordinateSequence().size() < kMinValidSize)) {
      throw ArgumentError(
        "${("Invalid number of points in LinearRing (found ${getCoordinateSequence().size()} - must be 0 or >= $kMinValidSize")})",
      );
    }
  }

  @override
  int getBoundaryDimension() => Dimension.kFalse;

  @override
  bool isClosed() {
    if (isEmpty()) {
      return true;
    }
    return super.isClosed();
  }

  @override
  GeometryType get geometryType => GeometryType.linearRing;

  @override
  LinearRing copyInternal() => LinearRing.of2(points.copy(), factory);

  @override
  LinearRing reverse() => (super.reverse() as LinearRing);

  @override
  LinearRing reverseInternal() {
    CoordinateSequence seq = points.copy();
    CoordinateSequences.reverse(seq);
    return factory.createLinearRing2(seq);
  }
}
