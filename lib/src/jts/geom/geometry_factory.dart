import 'dart:core' as c;
import 'dart:core';

 import 'package:d_util/d_util.dart';

import '../util/assert.dart';
import 'coordinate.dart';
import 'coordinate_sequence.dart';
import 'envelope.dart';
import 'geometry.dart';
import 'geometry_collection.dart';
import 'line_string.dart';
import 'linear_ring.dart';
import 'multi_line_string.dart';
import 'multi_point.dart';
import 'multi_polygon.dart';
import 'point.dart';
import 'polygon.dart';
import 'precision_model.dart';
import 'util/geometry_editor.dart';

final class GeometryFactory {
  final int srid;
  final PrecisionModel precisionModel;
  CoordinateSequenceFactory coordinateSequenceFactory;

  GeometryFactory.empty() : this(PrecisionModel(), 0, getDefaultCoordinateSequenceFactory());

  GeometryFactory(this.precisionModel, this.srid, this.coordinateSequenceFactory);

  GeometryFactory.of(CoordinateSequenceFactory coordinateSequenceFactory)
    : this(PrecisionModel(), 0, coordinateSequenceFactory);

  GeometryFactory.of2(PrecisionModel precisionModel, [int srid = 0])
    : this(precisionModel, srid, getDefaultCoordinateSequenceFactory());

  static Point createPointFromInternalCoord(Coordinate coord, Geometry exemplar) {
    exemplar.getPrecisionModel().makePrecise(coord);
    return exemplar.factory.createPoint2(coord);
  }

  static CoordinateSequenceFactory getDefaultCoordinateSequenceFactory() {
    return CoordinateArraySequenceFactory.instance();
  }

  static Array<Point> toPointArray(List<Point> points) {
    return points.toArray();
  }

  static Array<Geometry>? toGeometryArray(List<Geometry>? geometries) {
    if (geometries == null) {
      return null;
    }
    return geometries.toArray();
  }

  static Array<LinearRing> toLinearRingArray(List<LinearRing> linearRings) {
    return linearRings.toArray();
  }

  static Array<LineString> toLineStringArray(List<LineString> lineStrings) {
    return lineStrings.toArray();
  }

  static Array<Polygon> toPolygonArray(List<Polygon> polygons) {
    return polygons.toArray();
  }

  static Array<MultiPolygon> toMultiPolygonArray(List<MultiPolygon> multiPolygons) {
    return multiPolygons.toArray();
  }

  static Array<MultiLineString> toMultiLineStringArray(List<MultiLineString> multiLineStrings) {
    return multiLineStrings.toArray();
  }

  static Array<MultiPoint> toMultiPointArray(List<MultiPoint> multiPoints) {
    return multiPoints.toArray();
  }

  Geometry toGeometry(Envelope envelope) {
    if (envelope.isNull()) {
      return createPoint();
    }
    if ((envelope.getMinX() == envelope.getMaxX()) && (envelope.getMinY() == envelope.getMaxY())) {
      return createPoint2(Coordinate(envelope.getMinX(), envelope.getMinY()));
    }
    if ((envelope.getMinX() == envelope.getMaxX()) || (envelope.getMinY() == envelope.getMaxY())) {
      return createLineString2(
        [
          Coordinate(envelope.getMinX(), envelope.getMinY()),
          Coordinate(envelope.getMaxX(), envelope.getMaxY()),
        ].toArray(),
      );
    }
    return createPolygon(
      createLinearRing2(
        [
          Coordinate(envelope.getMinX(), envelope.getMinY()),
          Coordinate(envelope.getMinX(), envelope.getMaxY()),
          Coordinate(envelope.getMaxX(), envelope.getMaxY()),
          Coordinate(envelope.getMaxX(), envelope.getMinY()),
          Coordinate(envelope.getMinX(), envelope.getMinY()),
        ].toArray(),
      ),
      null,
    );
  }

  PrecisionModel getPrecisionModel() {
    return precisionModel;
  }

  Point createPoint() {
    return createPoint3(coordinateSequenceFactory.create(Array(0)));
  }

  Point createPoint2(Coordinate? coordinate) {
    return createPoint3(coordinate != null ? coordinateSequenceFactory.create([coordinate].toArray()) : null);
  }

  Point createPoint3(CoordinateSequence? coordinates) {
    return Point.of(coordinates, this);
  }

  MultiLineString createMultiLineString() {
    return MultiLineString(null, this);
  }

  MultiLineString createMultiLineString2(Array<LineString> lineStrings) {
    return MultiLineString(lineStrings, this);
  }

  GeometryCollection createGeometryCollection() {
    return GeometryCollection(null, this);
  }

  GeometryCollection createGeometryCollection2(Array<Geometry> geometries) {
    return GeometryCollection(geometries.asArray(), this);
  }

  MultiPolygon createMultiPolygon([Array<Polygon>? polygons]) {
    return MultiPolygon.of(polygons, this);
  }

  LinearRing createLinearRing() {
    return createLinearRing3(coordinateSequenceFactory.create(Array<Coordinate>(0)));
  }

  LinearRing createLinearRing2(Array<Coordinate>? coordinates) {
    return createLinearRing3(coordinates != null ? coordinateSequenceFactory.create(coordinates) : null);
  }

  LinearRing createLinearRing3(CoordinateSequence? coordinates) {
    return LinearRing.of2(coordinates, this);
  }

  MultiPoint createMultiPoint() {
    return MultiPoint(null, this);
  }

  MultiPoint createMultiPoint3(Array<Point> point) {
    return MultiPoint(point, this);
  }

  MultiPoint createMultiPoint2(Array<Coordinate>? coordinates) {
    return createMultiPoint4(coordinates != null ? coordinateSequenceFactory.create(coordinates) : null);
  }

  MultiPoint createMultiPointFromCoords(Array<Coordinate>? coordinates) {
    return createMultiPoint4(coordinates != null ? coordinateSequenceFactory.create(coordinates) : null);
  }

  MultiPoint createMultiPoint4(CoordinateSequence? coordinates) {
    if (coordinates == null) {
      return createMultiPoint3(Array(0));
    }
    Array<Point> points = Array(coordinates.size());
    for (int i = 0; i < coordinates.size(); i++) {
      CoordinateSequence ptSeq = coordinateSequenceFactory.create4(
        1,
        coordinates.getDimension(),
        coordinates.getMeasures(),
      );
      CoordinateSequences.copy(coordinates, i, ptSeq, 0, 1);
      points[i] = createPoint3(ptSeq);
    }
    return createMultiPoint3(points);
  }

  Polygon createPolygon([LinearRing? shell, Array<LinearRing>? holes]) {
    return Polygon(shell, holes, this);
  }

  Polygon createPolygon2(CoordinateSequence shell) {
    return createPolygon(createLinearRing3(shell));
  }

  Polygon createPolygon3(Array<Coordinate> shell) {
    return createPolygon(createLinearRing2(shell));
  }

  Geometry buildGeometry(List<Geometry> geomList) {
    c.Type? geomClass;
    bool isHeterogeneous = false;
    bool hasGeometryCollection = false;
    for (var geom in geomList) {
      var partClass = geom.runtimeType;
      geomClass ??= partClass;
      if (partClass != geomClass) {
        isHeterogeneous = true;
      }
      if (geom is GeometryCollection) {
        hasGeometryCollection = true;
      }
    }

    if (geomClass == null) {
      return createGeometryCollection();
    }
    if (isHeterogeneous || hasGeometryCollection) {
      return createGeometryCollection2(toGeometryArray(geomList)!);
    }

    Geometry geom0 = geomList.first;
    bool isCollection = geomList.size > 1;
    if (isCollection) {
      if (geom0 is Polygon) {
        return createMultiPolygon(toPolygonArray(geomList.cast()));
      } else if (geom0 is LineString) {
        return createMultiLineString2(toLineStringArray(geomList.cast()));
      } else if (geom0 is Point) {
        return createMultiPoint3(toPointArray(geomList.cast()));
      }
      Assert.shouldNeverReachHere2("Unhandled class: ${geom0.runtimeType}");
    }
    return geom0;
  }

  LineString createLineString([CoordinateSequence? coordinates]) {
    final v = coordinates ?? coordinateSequenceFactory.create(Array());
    return LineString.of(v, this);
  }

  LineString createLineString2(Array<Coordinate>? coordinates) {
    return createLineString(coordinates != null ? coordinateSequenceFactory.create(coordinates) : null);
  }

  Geometry createEmpty(int dimension) {
    switch (dimension) {
      case -1:
        return createGeometryCollection();
      case 0:
        return createPoint();
      case 1:
        return createLineString();
      case 2:
        return createPolygon();
      default:
        throw IllegalArgumentException("Invalid dimension: $dimension");
    }
  }

  Geometry? createGeometry(Geometry g) {
    final editor = GeometryEditor(this);
    return editor.edit(g, _CoordSeqCloneOp(coordinateSequenceFactory));
  }
}

class _CoordSeqCloneOp extends CoordinateSequenceOperation {
  CoordinateSequenceFactory coordinateSequenceFactory;

  _CoordSeqCloneOp(this.coordinateSequenceFactory);

  @override
  CoordinateSequence edit2(CoordinateSequence coordSeq, Geometry geometry) {
    return coordinateSequenceFactory.create2(coordSeq);
  }
}
