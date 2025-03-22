 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'coordinate.dart';
import 'coordinate_sequence.dart';
import 'dimension.dart';
import 'envelope.dart';
import 'geometry.dart';
import 'geometry_component_filter.dart';
import 'geometry_factory.dart';
import 'geometry_filter.dart';
import 'precision_model.dart';
import 'puntal.dart';

class Point extends BaseGeometry<Point> implements Puntal {
  late CoordinateSequence _coordinates;

  Point(Coordinate? coordinate, PrecisionModel precisionModel, int srid)
    : super(GeometryFactory.of2(precisionModel, srid)) {
    init(factory.coordinateSequenceFactory.create(coordinate != null ? Array.of(coordinate) : Array(0)));
  }

  Point.of(CoordinateSequence? coordinates, GeometryFactory factory) : super(factory) {
    init(coordinates);
  }

  void init(CoordinateSequence? coordinates) {
    coordinates ??= factory.coordinateSequenceFactory.create(Array(0));
    Assert.isTrue(coordinates.size() <= 1);
    _coordinates = coordinates;
  }

  @override
  Array<Coordinate> getCoordinates() {
    return isEmpty() ? Array(0) : Array.of(getCoordinate()!);
  }

  @override
  int getNumPoints() {
    return isEmpty() ? 0 : 1;
  }

  @override
  bool isEmpty() {
    return _coordinates.size() == 0;
  }

  @override
  bool isSimple() {
    return true;
  }

  @override
  int getDimension() {
    return 0;
  }

  @override
  int getBoundaryDimension() {
    return Dimension.FALSE;
  }

  double getX() {
    if (getCoordinate() == null) {
      throw ("getX called on empty Point");
    }
    return getCoordinate()!.x;
  }

  double getY() {
    if (getCoordinate() == null) {
      throw ("getY called on empty Point");
    }
    return getCoordinate()!.y;
  }

  @override
  Coordinate? getCoordinate() {
    return _coordinates.size() != 0 ? _coordinates.getCoordinate(0) : null;
  }

  @override
  GeometryType get geometryType {
    return GeometryType.point;
  }

  @override
  Geometry getBoundary() {
    return factory.createGeometryCollection();
  }

  @override
  Envelope computeEnvelopeInternal() {
    if (isEmpty()) {
      return Envelope();
    }
    Envelope env = Envelope();
    env.expandToInclude2(_coordinates.getX(0), _coordinates.getY(0));
    return env;
  }

  @override
  bool equalsExact2(Geometry other, double tolerance) {
    if (!isEquivalentClass(other)) {
      return false;
    }
    if (isEmpty() && other.isEmpty()) {
      return true;
    }
    if (isEmpty() != other.isEmpty()) {
      return false;
    }
    return equal((other as Point).getCoordinate()!, getCoordinate()!, tolerance);
  }

  @override
  void apply(CoordinateFilter filter) {
    if (isEmpty()) {
      return;
    }
    filter.filter(getCoordinate()!);
  }

  @override
  void apply2(CoordinateSequenceFilter filter) {
    if (isEmpty()) return;

    filter.filter(_coordinates, 0);
    if (filter.isGeometryChanged()) geometryChanged();
  }

  @override
  void apply3(GeometryFilter filter) {
    filter.filter(this);
  }

  @override
  void apply4(GeometryComponentFilter filter) {
    filter.filter(this);
  }

  @override
  Point clone() {
    return copy();
  }

  @override
  Point copyInternal() {
    return Point.of(_coordinates.copy(), factory);
  }

  @override
  Point reverseInternal() {
    return factory.createPoint3(_coordinates.copy());
  }

  @override
  void normalize() {}

  @override
  int compareToSameClass(Object other) {
    Point point = ((other as Point));
    return getCoordinate()!.compareTo(point.getCoordinate()!);
  }

  @override
  int compareToSameClass2(Object other, CoordinateSequenceComparator comp) {
    Point point = (other as Point);
    return comp.compare(_coordinates, point._coordinates);
  }

  CoordinateSequence getCoordinateSequence() {
    return _coordinates;
  }
}
