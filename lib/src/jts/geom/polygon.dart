import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/area.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';

import 'coordinate.dart';
import 'coordinate_sequence.dart';
import 'envelope.dart';
import 'geometry.dart';
import 'geometry_component_filter.dart';
import 'geometry_factory.dart';
import 'geometry_filter.dart';
import 'linear_ring.dart';
import 'polygonal.dart';
import 'precision_model.dart';

class Polygon extends BaseGeometry<Polygon> implements Polygonal {
  late LinearRing shell;
  late Array<LinearRing> holes;

  Polygon.of(LinearRing? shell, PrecisionModel precisionModel, int srid)
      : this.of2(shell, Array<LinearRing>(0), precisionModel, srid);

  Polygon.of2(LinearRing? shell, Array<LinearRing>? holes, PrecisionModel pm, int srid)
      : this(shell, holes, GeometryFactory(pm: pm, srid: srid));

  Polygon(LinearRing? shell, Array<LinearRing>? holes, GeometryFactory factory) : super(factory) {
    this.shell = shell ?? factory.createLinearRing();
    this.holes = holes ?? Array(0);

    if (Geometry.hasNullElements(this.holes)) {
      throw IllegalArgumentException("holes must not contain null elements");
    }
    if (this.shell.isEmpty() && Geometry.hasNonEmptyElements(this.holes)) {
      throw IllegalArgumentException("shell is empty but holes are not");
    }
  }

  @override
  Coordinate? getCoordinate() {
    return shell.getCoordinate();
  }

  @override
  Array<Coordinate> getCoordinates() {
    if (isEmpty()) {
      return Array(0);
    }
    Array<Coordinate> coordinates = Array(getNumPoints());
    int k = -1;
    Array<Coordinate> shellCoordinates = shell.getCoordinates();
    for (int x = 0; x < shellCoordinates.length; x++) {
      k++;
      coordinates[k] = shellCoordinates[x];
    }
    for (int i = 0; i < holes.length; i++) {
      Array<Coordinate> childCoordinates = holes[i].getCoordinates();
      for (int j = 0; j < childCoordinates.length; j++) {
        k++;
        coordinates[k] = childCoordinates[j];
      }
    }
    return coordinates;
  }

  @override
  int getNumPoints() {
    int numPoints = shell.getNumPoints();
    for (int i = 0; i < holes.length; i++) {
      numPoints += holes[i].getNumPoints();
    }
    return numPoints;
  }

  @override
  int getDimension() {
    return 2;
  }

  @override
  int getBoundaryDimension() {
    return 1;
  }

  @override
  bool isEmpty() {
    return shell.isEmpty();
  }

  @override
  bool isRectangle() {
    if (getNumInteriorRing() != 0) return false;

    if (shell.getNumPoints() != 5) return false;

    CoordinateSequence seq = shell.getCoordinateSequence();
    Envelope env = getEnvelopeInternal();
    for (int i = 0; i < 5; i++) {
      double x = seq.getX(i);
      if (!((x == env.minX) || (x == env.maxX))) return false;

      double y = seq.getY(i);
      if (!((y == env.minY) || (y == env.maxY))) return false;
    }
    double prevX = seq.getX(0);
    double prevY = seq.getY(0);
    for (int i = 1; i <= 4; i++) {
      double x = seq.getX(i);
      double y = seq.getY(i);
      bool xChanged = x != prevX;
      bool yChanged = y != prevY;
      if (xChanged == yChanged) return false;

      prevX = x;
      prevY = y;
    }
    return true;
  }

  LinearRing getExteriorRing() {
    return shell;
  }

  int getNumInteriorRing() {
    return holes.length;
  }

  LinearRing getInteriorRingN(int n) {
    return holes[n];
  }

  @override
  GeometryType get geometryType {
    return GeometryType.polygon;
  }

  @override
  double getArea() {
    double area = 0.0;
    area += Area.ofRing2(shell.getCoordinateSequence());
    for (int i = 0; i < holes.length; i++) {
      area -= Area.ofRing2(holes[i].getCoordinateSequence());
    }
    return area;
  }

  @override
  double getLength() {
    double len = 0.0;
    len += shell.getLength();
    for (int i = 0; i < holes.length; i++) {
      len += holes[i].getLength();
    }
    return len;
  }

  @override
  Geometry getBoundary() {
    if (isEmpty()) {
      return factory.createMultiLineString();
    }
    Array<LinearRing> rings = Array(holes.length + 1);
    rings[0] = shell;
    for (int i = 0; i < holes.length; i++) {
      rings[i + 1] = holes[i];
    }
    if (rings.length <= 1) return factory.createLinearRing2(rings[0].getCoordinateSequence());

    return factory.createMultiLineString(rings);
  }

  @override
  Envelope computeEnvelopeInternal() {
    return shell.getEnvelopeInternal();
  }

  @override
  bool equalsExact2(Geometry other, double tolerance) {
    if (!isEquivalentClass(other)) {
      return false;
    }
    Polygon otherPolygon = (other as Polygon);
    Geometry thisShell = shell;
    Geometry otherPolygonShell = otherPolygon.shell;
    if (!thisShell.equalsExact2(otherPolygonShell, tolerance)) {
      return false;
    }
    if (holes.length != otherPolygon.holes.length) {
      return false;
    }
    for (int i = 0; i < holes.length; i++) {
      if (!(holes[i] as Geometry).equalsExact2(otherPolygon.holes[i], tolerance)) {
        return false;
      }
    }
    return true;
  }

  @override
  void apply(CoordinateFilter filter) {
    shell.apply(filter);
    for (int i = 0; i < holes.length; i++) {
      holes[i].apply(filter);
    }
  }

  @override
  void apply2(CoordinateSequenceFilter filter) {
    shell.apply2(filter);
    if (!filter.isDone()) {
      for (int i = 0; i < holes.length; i++) {
        holes[i].apply2(filter);
        if (filter.isDone()) break;
      }
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
    shell.apply4(filter);
    for (int i = 0; i < holes.length; i++) {
      holes[i].apply4(filter);
    }
  }

  @override
  Polygon clone() {
    return copy();
  }

  @override
  Polygon copyInternal() {
    LinearRing shellCopy = shell.copy() as LinearRing;
    Array<LinearRing> holeCopies = Array(holes.length);
    for (int i = 0; i < holes.length; i++) {
      holeCopies[i] = (holes[i].copy() as LinearRing);
    }
    return Polygon(shellCopy, holeCopies, factory);
  }

  @override
  Geometry convexHull() {
    return getExteriorRing().convexHull();
  }

  @override
  void normalize() {
    shell = normalized(shell, true);
    for (int i = 0; i < holes.length; i++) {
      holes[i] = normalized(holes[i], false);
    }
    holes.sort();
  }

  @override
  int compareToSameClass(Object o) {
    Polygon poly = (o as Polygon);
    LinearRing thisShell = shell;
    LinearRing otherShell = poly.shell;
    int shellComp = thisShell.compareToSameClass(otherShell);
    if (shellComp != 0) return shellComp;

    int nHole1 = getNumInteriorRing();
    int nHole2 = o.getNumInteriorRing();
    int i = 0;
    while ((i < nHole1) && (i < nHole2)) {
      LinearRing thisHole = getInteriorRingN(i);
      LinearRing otherHole = poly.getInteriorRingN(i);
      int holeComp = thisHole.compareToSameClass(otherHole);
      if (holeComp != 0) return holeComp;

      i++;
    }
    if (i < nHole1) return 1;

    if (i < nHole2) return -1;

    return 0;
  }

  @override
  int compareToSameClass2(Object o, CoordinateSequenceComparator comp) {
    Polygon poly = (o as Polygon);
    LinearRing thisShell = shell;
    LinearRing otherShell = poly.shell;
    int shellComp = thisShell.compareToSameClass2(otherShell, comp);
    if (shellComp != 0) return shellComp;

    int nHole1 = getNumInteriorRing();
    int nHole2 = poly.getNumInteriorRing();
    int i = 0;
    while ((i < nHole1) && (i < nHole2)) {
      LinearRing thisHole = (getInteriorRingN(i));
      LinearRing otherHole = ((poly.getInteriorRingN(i)));
      int holeComp = thisHole.compareToSameClass2(otherHole, comp);
      if (holeComp != 0) return holeComp;

      i++;
    }
    if (i < nHole1) return 1;

    if (i < nHole2) return -1;

    return 0;
  }

  LinearRing normalized(LinearRing ring, bool clockwise) {
    LinearRing res = ((ring.copy() as LinearRing));
    normalize2(res, clockwise);
    return res;
  }

  void normalize2(LinearRing ring, bool clockwise) {
    if (ring.isEmpty()) {
      return;
    }
    CoordinateSequence seq = ring.getCoordinateSequence();
    int minCoordinateIndex = CoordinateSequences.minCoordinateIndex2(seq, 0, seq.size() - 2);
    CoordinateSequences.scroll3(seq, minCoordinateIndex, true);
    if (Orientation.isCCW2(seq) == clockwise) CoordinateSequences.reverse(seq);
  }

  @override
  Polygon reverseInternal() {
    LinearRing shell = getExteriorRing().reverse();
    Array<LinearRing> holes = Array(getNumInteriorRing());
    for (int i = 0; i < holes.length; i++) {
      holes[i] = getInteriorRingN(i).reverse();
    }
    return factory.createPolygon(shell, holes);
  }
}
