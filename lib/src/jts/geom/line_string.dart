import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/length.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/operation/boundary_op.dart';

import 'coordinate.dart';
import 'coordinate_sequence.dart';
import 'dimension.dart';
import 'envelope.dart';
import 'geometry.dart';
import 'geometry_component_filter.dart';
import 'geometry_factory.dart';
import 'geometry_filter.dart';
import 'lineal.dart';
import 'precision_model.dart';

class LineString extends BaseGeometry<LineString> implements Lineal {
  static const int _minValidSize = 2;

  late CoordinateSequence points;

  LineString(Array<Coordinate>? points, PrecisionModel precisionModel, int srid)
      : super(GeometryFactory.from(precisionModel, srid)) {
    init(factory.csFactory.create(points));
  }

  LineString.of(CoordinateSequence? points, GeometryFactory factory) : super(factory) {
    init(points);
  }

  void init(CoordinateSequence? points) {
    points ??= factory.csFactory.create(Array(0));
    if ((points.size() > 0) && (points.size() < _minValidSize)) {
      throw ("Invalid number of points in LineString (found ${points.size()}"
          " - must be 0 or >= $_minValidSize");
    }
    this.points = points;
  }

  @override
  Array<Coordinate> getCoordinates() {
    return points.toCoordinateArray();
  }

  CoordinateSequence getCoordinateSequence() {
    return points;
  }

  Coordinate getCoordinateN(int n) {
    return points.getCoordinate(n);
  }

  @override
  Coordinate? getCoordinate() {
    if (isEmpty()) {
      return null;
    }

    return points.getCoordinate(0);
  }

  @override
  int getDimension() {
    return 1;
  }

  @override
  int getBoundaryDimension() {
    if (isClosed()) {
      return Dimension.False;
    }
    return 0;
  }

  @override
  bool isEmpty() {
    return points.size() == 0;
  }

  @override
  int getNumPoints() {
    return points.size();
  }

  Point getPointN(int n) {
    return factory.createPoint2(points.getCoordinate(n));
  }

  Point? getStartPoint() {
    if (isEmpty()) {
      return null;
    }
    return getPointN(0);
  }

  Point? getEndPoint() {
    if (isEmpty()) {
      return null;
    }
    return getPointN(getNumPoints() - 1);
  }

  bool isClosed() {
    if (isEmpty()) {
      return false;
    }
    return getCoordinateN(0).equals2D(getCoordinateN(getNumPoints() - 1));
  }

  bool isRing() {
    return isClosed() && isSimple();
  }

  @override
  GeometryType get geometryType {
    return GeometryType.lineString;
  }

  @override
  double getLength() {
    return Length.ofLine(points);
  }

  @override
  Geometry? getBoundary() {
    return BoundaryOp(this).getBoundary();
  }

  @override
  LineString reverseInternal() {
    CoordinateSequence seq = points.copy();
    CoordinateSequences.reverse(seq);
    return factory.createLineString(seq);
  }

  bool isCoordinate(Coordinate pt) {
    for (int i = 0; i < points.size(); i++) {
      if (points.getCoordinate(i).equals(pt)) {
        return true;
      }
    }
    return false;
  }

  @override
  Envelope computeEnvelopeInternal() {
    if (isEmpty()) {
      return Envelope();
    }
    return points.expandEnvelope(Envelope());
  }

  @override
  bool equalsExact2(Geometry other, double tolerance) {
    if (!isEquivalentClass(other)) {
      return false;
    }
    LineString otherLineString = (other as LineString);
    if (points.size() != otherLineString.points.size()) {
      return false;
    }
    for (int i = 0; i < points.size(); i++) {
      if (!equal(points.getCoordinate(i), otherLineString.points.getCoordinate(i), tolerance)) {
        return false;
      }
    }
    return true;
  }

  @override
  void apply(CoordinateFilter filter) {
    for (int i = 0; i < points.size(); i++) {
      filter.filter(points.getCoordinate(i));
    }
  }

  @override
  void apply2(CoordinateSequenceFilter filter) {
    if (points.size() == 0) return;

    for (int i = 0; i < points.size(); i++) {
      filter.filter(points, i);
      if (filter.isDone()) break;
    }
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
  LineString clone() {
    return copy();
  }

  @override
  LineString copyInternal() {
    return LineString.of(points.copy(), factory);
  }

  @override
  void normalize() {
    for (int i = 0; i < (points.size() / 2); i++) {
      int j = (points.size() - 1) - i;
      if (!points.getCoordinate(i).equals(points.getCoordinate(j))) {
        if (points.getCoordinate(i).compareTo(points.getCoordinate(j)) > 0) {
          CoordinateSequence copy = points.copy();
          CoordinateSequences.reverse(copy);
          points = copy;
        }
        return;
      }
    }
  }

  @override
  bool isEquivalentClass(Geometry other) {
    return other is LineString;
  }

  @override
  int compareToSameClass(Object o) {
    LineString line = (o as LineString);
    int i = 0;
    int j = 0;
    while ((i < points.size()) && (j < line.points.size())) {
      int comparison = points.getCoordinate(i).compareTo(line.points.getCoordinate(j));
      if (comparison != 0) {
        return comparison;
      }
      i++;
      j++;
    }
    if (i < points.size()) {
      return 1;
    }
    if (j < line.points.size()) {
      return -1;
    }
    return 0;
  }

  @override
  int compareToSameClass2(Object o, CoordinateSequenceComparator comp) {
    LineString line = ((o as LineString));
    return comp.compare(points, line.points);
  }
}
