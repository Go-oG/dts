import 'dart:core' as c;
import 'dart:core';
import 'dart:ui';

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
import 'util/geom_editor.dart';

final class GeometryFactory {
  late final int srid;
  late final PrecisionModel pm;
  late CoordinateSequenceFactory csFactory;

  GeometryFactory({PrecisionModel? pm, this.srid = 0, CoordinateSequenceFactory? csFactory}) {
    this.pm = pm ?? PrecisionModel();
    this.csFactory = csFactory ?? getDefaultCoordinateSequenceFactory();
  }

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
    if (envelope.isNull) {
      return createPoint();
    }
    if ((envelope.minX == envelope.maxX) && (envelope.minY == envelope.maxY)) {
      return createPoint2(Coordinate(envelope.minX, envelope.minY));
    }
    if ((envelope.minX == envelope.maxX) || (envelope.minY == envelope.maxY)) {
      return createLineString2(
        [
          Coordinate(envelope.minX, envelope.minY),
          Coordinate(envelope.maxX, envelope.maxY),
        ].toArray(),
      );
    }
    return createPolygon(
      createLinearRings(
        [
          Coordinate(envelope.minX, envelope.minY),
          Coordinate(envelope.minX, envelope.maxY),
          Coordinate(envelope.maxX, envelope.maxY),
          Coordinate(envelope.maxX, envelope.minY),
          Coordinate(envelope.minX, envelope.minY),
        ].toArray(),
      ),
      null,
    );
  }

  PrecisionModel getPrecisionModel() {
    return pm;
  }

  Point createPoint() {
    return createPoint3(csFactory.create(Array(0)));
  }

  Point createPoint2(Coordinate? coordinate) {
    return createPoint3(coordinate != null ? csFactory.create([coordinate].toArray()) : null);
  }

  Point createPoint3(CoordinateSequence? cs) {
    return Point.of(cs, this);
  }

  Point createPoint4(Offset offset) => createPoint2(Coordinate.of2(offset));

  MultiLineString createMultiLineString([Array<LineString>? lineStrings]) {
    return MultiLineString(lineStrings, this);
  }

  GeometryCollection createGeomCollection([Array<Geometry>? geometries]) {
    return GeometryCollection(geometries?.asArray(), this);
  }

  MultiPolygon createMultiPolygon([Array<Polygon>? polygons]) {
    return MultiPolygon.of(polygons, this);
  }

  MultiPolygon createMultiPolygon2(List<Polygon> polygons) {
    return createMultiPolygon(Array.list(polygons));
  }

  LinearRing createLinearRing() {
    return createLinearRing2(csFactory.create(Array<Coordinate>(0)));
  }

  LinearRing createLinearRings([Array<Coordinate>? coordinates]) {
    return createLinearRing2(coordinates != null ? csFactory.create(coordinates) : null);
  }

  LinearRing createLinearRing2(CoordinateSequence? coordinates) {
    return LinearRing.of2(coordinates, this);
  }

  LinearRing createLinearRing4([List<Offset>? coordinates]) {
    if (coordinates == null) {
      return createLinearRings();
    }
    return createLinearRings(Array.list(coordinates.map((e) => Coordinate.of2(e))));
  }

  MultiPoint createMultiPoint([Array<Point>? point]) => MultiPoint(point, this);

  MultiPoint createMultiPoint2([Array<Coordinate>? coordinates]) {
    return createMultiPoint3(coordinates != null ? csFactory.create(coordinates) : null);
  }

  MultiPoint createMultiPoint3(CoordinateSequence? coordinates) {
    if (coordinates == null) {
      return createMultiPoint(Array(0));
    }
    Array<Point> points = Array(coordinates.size());
    for (int i = 0; i < coordinates.size(); i++) {
      CoordinateSequence ptSeq = csFactory.create4(
        1,
        coordinates.getDimension(),
        coordinates.getMeasures(),
      );
      CoordinateSequences.copy(coordinates, i, ptSeq, 0, 1);
      points[i] = createPoint3(ptSeq);
    }
    return createMultiPoint(points);
  }

  MultiPoint createMultiPoint4(Array<Coordinate>? coordinates) {
    return createMultiPoint3(coordinates != null ? csFactory.create(coordinates) : null);
  }

  MultiPoint createMultiPoint5([List<Offset>? point]) {
    if (point == null) {
      return createMultiPoint();
    }
    return createMultiPoint2(Array.list(point.map((e) => Coordinate.of2(e))));
  }

  Polygon createPolygon([LinearRing? shell, Array<LinearRing>? holes]) {
    return Polygon(shell, holes, this);
  }

  Polygon createPolygon2(CoordinateSequence shell) {
    return createPolygon(createLinearRing2(shell));
  }

  Polygon createPolygon3(Array<Coordinate> shell) {
    return createPolygon(createLinearRings(shell));
  }

  Polygon createPolygon4(List<Coordinate> vertexList, [bool close = true]) {
    Array<Coordinate> array;
    if (close) {
      if (vertexList.first != vertexList.last) {
        array = Array.list([...vertexList, vertexList.first]);
      } else {
        array = Array.list(vertexList);
      }
    } else {
      array = Array.list(vertexList);
    }
    return createPolygon3(array);
  }

  Polygon createPolygon5(List<Offset> vertexList, [bool close = true]) {
    var list = vertexList.map((e) => Coordinate.of2(e)).toList();
    return createPolygon4(list, close);
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
      return createGeomCollection();
    }
    if (isHeterogeneous || hasGeometryCollection) {
      return createGeomCollection(toGeometryArray(geomList)!);
    }

    Geometry geom0 = geomList.first;
    bool isCollection = geomList.size > 1;
    if (isCollection) {
      if (geom0 is Polygon) {
        return createMultiPolygon(toPolygonArray(geomList.cast()));
      } else if (geom0 is LineString) {
        return createMultiLineString(toLineStringArray(geomList.cast()));
      } else if (geom0 is Point) {
        return createMultiPoint(toPointArray(geomList.cast()));
      }
      Assert.shouldNeverReachHere("Unhandled class: ${geom0.runtimeType}");
    }
    return geom0;
  }

  LineString createLineString([CoordinateSequence? coordinates]) {
    final v = coordinates ?? csFactory.create(Array());
    return LineString.of(v, this);
  }

  LineString createLineString2([Array<Coordinate>? coordinates]) {
    return createLineString(coordinates != null ? csFactory.create(coordinates) : null);
  }

  LineString createLineString3([List<Offset>? coordinates]) {
    if (coordinates == null) {
      return createLineString2();
    }
    final array = Array.list(coordinates.map((e) => Coordinate.of2(e)));
    return createLineString2(array);
  }

  Geometry createEmpty(int dimension) {
    switch (dimension) {
      case -1:
        return createGeomCollection();
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

  Geometry? createGeom(Geometry g) {
    final editor = GeometryEditor(this);
    return editor.edit(g, _CoordSeqCloneOp(csFactory));
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
