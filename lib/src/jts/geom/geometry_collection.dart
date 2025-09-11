import 'dart:collection';

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
import 'line_string.dart';
import 'point.dart';
import 'polygon.dart';
import 'precision_model.dart';

class GeometryCollection<T extends Geometry> extends BaseGeometry<GeometryCollection<T>> {
  late List<T> geometries;

  GeometryCollectionDimension? _geomCollDim;

  GeometryCollection.of(List<T>? geometries, PrecisionModel pm, int srid)
      : this(geometries, GeometryFactory(pm: pm, srid: srid));

  GeometryCollection(List<T>? geometries, GeometryFactory factory) : super(factory) {
    this.geometries = geometries ?? List.empty(growable: false);
    if (Geometry.hasNullElements(this.geometries)) {
      throw IllegalArgumentException("geometries must not contain null elements");
    }
  }

  @override
  Coordinate? getCoordinate() {
    for (var i = 0; i < geometries.length; i++) {
      if (!geometries[i].isEmpty()) {
        return geometries[i].getCoordinate();
      }
    }
    return null;
  }

  @override
  List<Coordinate> getCoordinates() {
    List<Coordinate> coordinates = [];
    for (int i = 0; i < geometries.length; i++) {
      final childCoordinates = geometries[i].getCoordinates();
      for (int j = 0; j < childCoordinates.length; j++) {
        coordinates.add(childCoordinates[j]);
      }
    }
    return coordinates;
  }

  @override
  bool isEmpty() {
    for (int i = 0; i < geometries.length; i++) {
      if (!geometries[i].isEmpty()) {
        return false;
      }
    }
    return true;
  }

  @override
  int getDimension() {
    _geomCollDim ??= GeometryCollectionDimension(this);
    return _geomCollDim!.getDimension();
  }

  @override
  bool hasDimension(int dim) {
    _geomCollDim ??= GeometryCollectionDimension(this);
    return _geomCollDim!.hasDimension(dim);
  }

  @override
  int getBoundaryDimension() {
    int dimension = Dimension.kFalse;
    for (int i = 0; i < geometries.length; i++) {
      dimension = Math.max(dimension, (geometries[i]).getBoundaryDimension()).toInt();
    }
    return dimension;
  }

  @override
  int getNumGeometries() {
    return geometries.length;
  }

  @override
  T getGeometryN(int n) {
    return geometries[n];
  }

  @override
  int getNumPoints() {
    int numPoints = 0;
    for (int i = 0; i < geometries.length; i++) {
      numPoints += (geometries[i]).getNumPoints();
    }
    return numPoints;
  }

  @override
  GeometryType get geometryType {
    return GeometryType.collection;
  }

  @override
  Geometry? getBoundary() {
    Geometry.checkNotGeometryCollection(this);
    Assert.shouldNeverReachHere();
    return null;
  }

  @override
  double getArea() {
    double area = 0.0;
    for (int i = 0; i < geometries.length; i++) {
      area += geometries[i].getArea();
    }
    return area;
  }

  @override
  double getLength() {
    double sum = 0.0;
    for (int i = 0; i < geometries.length; i++) {
      sum += geometries[i].getLength();
    }
    return sum;
  }

  @override
  bool equalsExact2(Geometry other, double tolerance) {
    if (!isEquivalentClass(other)) {
      return false;
    }
    GeometryCollection otherCollection = (other as GeometryCollection);
    if (geometries.length != otherCollection.geometries.length) {
      return false;
    }
    for (int i = 0; i < geometries.length; i++) {
      if (!(geometries[i]).equalsExact2(otherCollection.geometries[i], tolerance)) {
        return false;
      }
    }
    return true;
  }

  @override
  void apply(CoordinateFilter filter) {
    for (int i = 0; i < geometries.length; i++) {
      geometries[i].apply(filter);
    }
  }

  @override
  void apply2(CoordinateSequenceFilter filter) {
    if (geometries.isEmpty) return;

    for (int i = 0; i < geometries.length; i++) {
      geometries[i].apply2(filter);
      if (filter.isDone()) {
        break;
      }
    }
    if (filter.isGeometryChanged()) geometryChanged();
  }

  @override
  void apply3(GeometryFilter filter) {
    filter.filter(this);
    for (int i = 0; i < geometries.length; i++) {
      geometries[i].apply3(filter);
    }
  }

  @override
  void apply4(GeometryComponentFilter filter) {
    filter.filter(this);
    for (int i = 0; i < geometries.length; i++) {
      geometries[i].apply4(filter);
    }
  }

  @override
  GeometryCollection<T> clone() {
    return copy();
  }

  @override
  GeometryCollection<T> copyInternal() {
    final List<T> geometries = this.geometries.map((e) => e.copy() as T).toList();
    return GeometryCollection(geometries, factory);
  }

  @override
  void normalize() {
    for (int i = 0; i < geometries.length; i++) {
      geometries[i].normalize();
    }
    geometries.sort();
  }

  @override
  Envelope computeEnvelopeInternal() {
    Envelope envelope = Envelope();
    for (int i = 0; i < geometries.length; i++) {
      envelope.expandToInclude(geometries[i].getEnvelopeInternal());
    }
    return envelope;
  }

  @override
  int compareToSameClass(Object o) {
    Set<T> theseElements = SplayTreeSet();
    theseElements.addAll(geometries);
    Set<T> otherElements = SplayTreeSet();
    otherElements.addAll((o as GeometryCollection<T>).geometries);
    return compare(theseElements, otherElements);
  }

  @override
  int compareToSameClass2(Object o, CoordinateSequenceComparator comp) {
    GeometryCollection gc = (o as GeometryCollection);
    int n1 = getNumGeometries();
    int n2 = gc.getNumGeometries();
    int i = 0;
    while ((i < n1) && (i < n2)) {
      Geometry thisGeom = getGeometryN(i);
      Geometry otherGeom = gc.getGeometryN(i);
      int holeComp = thisGeom.compareToSameClass2(otherGeom, comp);
      if (holeComp != 0) return holeComp;

      i++;
    }
    if (i < n1) return 1;

    if (i < n2) return -1;

    return 0;
  }

  @override
  GeometryCollection<T> reverseInternal() {
    return GeometryCollection(this.geometries.map((e) => (e.reverse() as T)).toList(), factory);
  }
}

class GeometryCollectionDimension {
  int _dimension = Dimension.kFalse;

  bool _hasP = false;

  bool _hasL = false;

  bool _hasA = false;

  GeometryCollectionDimension(GeometryCollection coll) {
    init(coll);
  }

  void init(GeometryCollection coll) {
    Iterator geomi = GeometryCollectionIterator(coll);
    while (geomi.moveNext()) {
      Geometry elem = (geomi.current as Geometry);
      if (elem is Point) {
        _hasP = true;
        if (_dimension < Dimension.P) {
          _dimension = Dimension.P;
        }
      }
      if (elem is LineString) {
        _hasL = true;
        if (_dimension < Dimension.L) {
          _dimension = Dimension.L;
        }
      }
      if (elem is Polygon) {
        _hasA = true;
        if (_dimension < Dimension.A) {
          _dimension = Dimension.A;
        }
      }
    }
  }

  bool hasDimension(int dim) {
    switch (dim) {
      case Dimension.A:
        return _hasA;
      case Dimension.L:
        return _hasL;
      case Dimension.P:
        return _hasP;
    }
    return false;
  }

  int getDimension() {
    return _dimension;
  }
}

class GeometryCollectionIterator implements Iterator {
  final Geometry _parent;

  late bool _atStart;

  late int _max;

  late int index;

  GeometryCollectionIterator? _subcollectionIterator;

  GeometryCollectionIterator(this._parent) {
    _atStart = true;
    index = 0;
    _max = _parent.getNumGeometries();
  }

  bool _hasNext() {
    if (_atStart) {
      return true;
    }
    if (_subcollectionIterator != null) {
      if (_subcollectionIterator!._hasNext()) {
        return true;
      }
      _subcollectionIterator = null;
    }
    if (index >= _max) {
      return false;
    }
    return true;
  }

  Object _next() {
    if (_atStart) {
      _atStart = false;
      if (isAtomic(_parent)) index++;

      return _parent;
    }
    if (_subcollectionIterator != null) {
      if (_subcollectionIterator!._hasNext()) {
        return _subcollectionIterator!._next();
      } else {
        _subcollectionIterator = null;
      }
    }
    if (index >= _max) {
      throw "NoSuchElementException";
    }
    Geometry obj = _parent.getGeometryN(index++);
    if (obj is GeometryCollection) {
      _subcollectionIterator = GeometryCollectionIterator(obj);
      return _subcollectionIterator!._next();
    }
    return obj;
  }

  static bool isAtomic(Geometry geom) {
    return geom is! GeometryCollection;
  }

  @override
  get current => _next();

  @override
  bool moveNext() {
    return _hasNext();
  }
}
