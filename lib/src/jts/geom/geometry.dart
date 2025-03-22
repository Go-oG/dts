 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/centroid.dart';
import 'package:dts/src/jts/algorithm/convex_hull.dart';
import 'package:dts/src/jts/algorithm/interior_point.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/operation/buffer/buffer_op.dart';
import 'package:dts/src/jts/operation/distance/distance_op.dart';
import 'package:dts/src/jts/operation/predicate/rectangle_contains.dart';
import 'package:dts/src/jts/operation/predicate/rectangle_intersects.dart';
import 'package:dts/src/jts/operation/valid/is_simple_op.dart';
import 'package:dts/src/jts/operation/valid/is_valid_op.dart';

import 'coordinate.dart';
import 'coordinate_sequence.dart';
import 'envelope.dart';
import 'geometry_component_filter.dart';
import 'geometry_factory.dart';
import 'geometry_filter.dart';
import 'geometry_overlay.dart';
import 'geometry_relate.dart';
import 'intersection_matrix.dart';
import 'precision_model.dart';

enum GeometryType {
  point("Point", 0),
  multiPoint("MultiPoint", 1),
  lineString("LineString", 2),
  linearRing("LinearRing", 3),
  multiLineString("MultiLineString", 4),
  polygon("Polygon", 5),
  multiPolygon("MultiPolygon", 6),
  collection("GeometryCollection", 7);

  final String key;
  final int code;

  const GeometryType(this.key, this.code);
}

abstract class Geometry implements Comparable<Geometry> {
  static final _geometryChangedFilter = GeometryComponentFilter2((geom) {
    geom.geometryChangedAction();
  });

  late final GeometryFactory factory;
  int srid = 0;

  Envelope? envelope;

  dynamic userData;

  Geometry(this.factory) {
    srid = factory.srid;
  }

  static bool hasNonEmptyElements(Array<Geometry> geometries) {
    for (int i = 0; i < geometries.length; i++) {
      if (!geometries[i].isEmpty()) {
        return true;
      }
    }
    return false;
  }

  static bool hasNullElements(Array<Object?> array) {
    for (int i = 0; i < array.length; i++) {
      if (array[i] == null) {
        return true;
      }
    }
    return false;
  }

  int getNumGeometries() {
    return 1;
  }

  Geometry getGeometryN(int n) {
    return this;
  }

  PrecisionModel getPrecisionModel() {
    return factory.getPrecisionModel();
  }

  Coordinate? getCoordinate();

  Array<Coordinate> getCoordinates();

  int getNumPoints();

  bool isSimple() {
    IsSimpleOp op = IsSimpleOp(this);
    return op.isSimple();
  }

  bool isValid() {
    return IsValidOp.isValid3(this);
  }

  bool isEmpty();

  double distance(Geometry g) {
    return DistanceOp.distanceS(this, g);
  }

  bool isWithinDistance(Geometry geom, double distance) {
    return DistanceOp.isWithinDistance(this, geom, distance);
  }

  bool isRectangle() {
    return false;
  }

  double getArea() {
    return 0.0;
  }

  double getLength() {
    return 0.0;
  }

  Point getCentroid() {
    if (isEmpty()) {
      return factory.createPoint();
    }

    Coordinate centPt = Centroid.getCentroidS(this);
    return createPointFromInternalCoord(centPt, this);
  }

  Point getInteriorPoint() {
    if (isEmpty()) {
      return factory.createPoint();
    }

    Coordinate pt = InteriorPoint.getInteriorPoint(this)!;
    return createPointFromInternalCoord(pt, this);
  }

  int getDimension();

  bool hasDimension(int dim) {
    return dim == getDimension();
  }

  Geometry? getBoundary();

  int getBoundaryDimension();

  Geometry getEnvelope() {
    return factory.toGeometry(getEnvelopeInternal());
  }

  Envelope getEnvelopeInternal() {
    envelope ??= computeEnvelopeInternal();
    return Envelope.of2(envelope!);
  }

  void geometryChanged() {
    apply4(_geometryChangedFilter);
  }

  void geometryChangedAction() {
    envelope = null;
  }

  bool disjoint(Geometry g) {
    return !intersects(g);
  }

  bool touches(Geometry g) {
    return GeometryRelate.touches(this, g);
  }

  bool intersects(Geometry g) {
    if (!getEnvelopeInternal().intersects6(g.getEnvelopeInternal())) return false;

    if (isRectangle()) {
      return RectangleIntersects.intersects2(this as Polygon, g);
    }
    if (g.isRectangle()) {
      return RectangleIntersects.intersects2(g as Polygon, this);
    }
    return GeometryRelate.intersects(this, g);
  }

  bool crosses(Geometry g) {
    if (!getEnvelopeInternal().intersects6(g.getEnvelopeInternal())) return false;

    return relate(g).isCrosses(getDimension(), g.getDimension());
  }

  bool within(Geometry g) {
    return GeometryRelate.within(this, g);
  }

  bool contains(Geometry g) {
    if (isRectangle()) {
      return RectangleContains.containsS(this as Polygon, g);
    }
    return GeometryRelate.contains(this, g);
  }

  bool overlaps(Geometry g) {
    return GeometryRelate.overlaps(this, g);
  }

  bool covers(Geometry g) {
    return GeometryRelate.covers(this, g);
  }

  bool coveredBy(Geometry g) {
    return GeometryRelate.coveredBy(this, g);
  }

  bool relate2(Geometry g, String intersectionPattern) {
    return GeometryRelate.relate2(this, g, intersectionPattern);
  }

  IntersectionMatrix relate(Geometry g) {
    return GeometryRelate.relate(this, g);
  }

  GeometryType get geometryType;

  bool equals2(Geometry? g) {
    if (g == null) {
      return false;
    }

    return equalsTopo(g);
  }

  bool equalsTopo(Geometry g) {
    return GeometryRelate.equalsTopo(this, g);
  }

  bool equals(Object o) {
    if (o is! Geometry) return false;
    return equalsExact(o);
  }

  @override
  int get hashCode {
    return getEnvelopeInternal().hashCode;
  }

  @override
  bool operator ==(Object other) {
    return equals(other);
  }

  Geometry buffer(double distance) {
    return BufferOp.bufferOp(this, distance);
  }

  Geometry buffer2(double distance, int quadrantSegments) {
    return BufferOp.bufferOp2(this, distance, quadrantSegments);
  }

  Geometry buffer3(double distance, int quadrantSegments, int endCapStyle) {
    return BufferOp.bufferOp4(this, distance, quadrantSegments, endCapStyle);
  }

  Geometry convexHull() {
    return ConvexHull.of(this).getConvexHull();
  }

  Geometry reverse() {
    Geometry res = reverseInternal();
    if (envelope != null) {
      res.envelope = envelope!.copy();
    }
    res.srid = srid;
    return res;
  }

  Geometry reverseInternal();

  Geometry? intersection(Geometry other) {
    return GeometryOverlay.intersection(this, other);
  }

  Geometry? union2(Geometry other) {
    return GeometryOverlay.union2(this, other);
  }

  Geometry? difference(Geometry other) {
    return GeometryOverlay.difference(this, other);
  }

  Geometry? symDifference(Geometry other) {
    return GeometryOverlay.symDifference(this, other);
  }

  Geometry? union() {
    return GeometryOverlay.union(this);
  }

  bool equalsExact(Geometry other) {
    return (this == other) || equalsExact2(other, 0);
  }

  bool equalsExact2(Geometry other, double tolerance);

  bool equalsNorm(Geometry? g) {
    if (g == null) return false;

    return norm().equalsExact(g.norm());
  }

  void apply(CoordinateFilter filter);

  void apply2(CoordinateSequenceFilter filter);

  void apply3(GeometryFilter filter);

  void apply4(GeometryComponentFilter filter);

  Geometry clone() {
    return copy();
  }

  Geometry copy() {
    Geometry copy = copyInternal();
    copy.envelope = (envelope == null) ? null : envelope!.copy();
    copy.srid = srid;
    copy.userData = userData;
    return copy;
  }

  Geometry copyInternal();

  void normalize();

  Geometry norm() {
    Geometry copyV = copy();
    copyV.normalize();
    return copyV;
  }

  @override
  int compareTo(Geometry other) {
    if (geometryType != other.geometryType) {
      return geometryType.code - geometryType.code;
    }
    if (isEmpty() && other.isEmpty()) {
      return 0;
    }
    if (isEmpty()) {
      return -1;
    }
    if (other.isEmpty()) {
      return 1;
    }
    return compareToSameClass(other);
  }

  int compareTo2(Geometry other, CoordinateSequenceComparator comp) {
    if (geometryType != other.geometryType) {
      return geometryType.code - other.geometryType.code;
    }
    if (isEmpty() && other.isEmpty()) {
      return 0;
    }
    if (isEmpty()) {
      return -1;
    }
    if (other.isEmpty()) {
      return 1;
    }
    return compareToSameClass2(other, comp);
  }

  bool isEquivalentClass(Geometry other) {
    return runtimeType == other.runtimeType;
  }

  static void checkNotGeometryCollection(Geometry g) {
    if (g.isGeometryCollection()) {
      throw IllegalArgumentException("Operation does not support GeometryCollection arguments");
    }
  }

  bool isGeometryCollection() {
    return geometryType == GeometryType.collection;
  }

  Envelope computeEnvelopeInternal();

  int compareToSameClass(Object o);

  int compareToSameClass2(Object o, CoordinateSequenceComparator comp);

  int compare(Iterable<Comparable> a, Iterable<Comparable> b) {
    Iterator i = a.iterator;
    Iterator j = b.iterator;

    while (i.moveNext() && j.moveNext()) {
      Comparable aElement = i.current;
      Comparable bElement = j.current;
      int comparison = aElement.compareTo(bElement);
      if (comparison != 0) {
        return comparison;
      }
    }
    if (i.moveNext()) {
      return 1;
    }
    if (j.moveNext()) {
      return -1;
    }
    return 0;
  }

  bool equal(Coordinate a, Coordinate b, double tolerance) {
    if (tolerance == 0) {
      return a.equals(b);
    }
    return a.distance(b) <= tolerance;
  }

  Point createPointFromInternalCoord(Coordinate? coord, Geometry exemplar) {
    if (coord == null) return exemplar.factory.createPoint();

    exemplar.getPrecisionModel().makePrecise(coord);
    return exemplar.factory.createPoint2(coord);
  }
}

abstract class BaseGeometry<T extends Geometry> extends Geometry {
  BaseGeometry(super.factory);

  @override
  T clone() {
    return copy();
  }

  @override
  T copy() {
    var t = super.copy();
    return t as T;
  }

  @override
  T copyInternal();

  @override
  T norm() {
    var t = super.norm();
    return t as T;
  }

  @override
  T reverse() {
    return super.reverse() as T;
  }

  @override
  T reverseInternal();
}
