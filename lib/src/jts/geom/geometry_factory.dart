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
  final int srid;
  final PrecisionModel pm;
  final CoordinateSequenceFactory csFactory;

  GeometryFactory({PrecisionModel? pm, this.srid = 0, CoordinateSequenceFactory? csFactory})
      : pm = pm ?? PrecisionModel(),
        csFactory = csFactory ?? getDefaultCoordinateSequenceFactory();

  static Point createPointFromInternalCoord(Coordinate coord, Geometry exemplar) {
    exemplar.getPrecisionModel().makePrecise(coord);
    return exemplar.factory.createPoint2(coord);
  }

  static CoordinateSequenceFactory getDefaultCoordinateSequenceFactory() {
    return CoordinateArraySequenceFactory.instance();
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
        ],
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
        ],
      ),
      null,
    );
  }

  PrecisionModel getPrecisionModel() {
    return pm;
  }

  Point createPoint() => createPoint3(csFactory.create([]));

  Point createPoint2(Coordinate? coordinate) {
    return createPoint3(coordinate != null ? csFactory.create([coordinate]) : null);
  }

  Point createPoint3(CoordinateSequence? cs) {
    return Point.of(cs, this);
  }

  Point createPoint4(Offset offset) => createPoint2(Coordinate.of2(offset));

  MultiLineString createMultiLineString([List<LineString>? lineStrings]) {
    return MultiLineString(lineStrings, this);
  }

  GeometryCollection createGeomCollection([List<Geometry>? geometries]) {
    return GeometryCollection(geometries, this);
  }

  MultiPolygon createMultiPolygon([List<Polygon>? polygons]) => MultiPolygon.of(polygons, this);

  LinearRing createLinearRing() {
    return createLinearRing2(csFactory.create([]));
  }

  LinearRing createLinearRings([List<Coordinate>? coordinates]) {
    return createLinearRing2(coordinates != null ? csFactory.create(coordinates) : null);
  }

  LinearRing createLinearRing2(CoordinateSequence? coordinates) {
    return LinearRing.of2(coordinates, this);
  }

  LinearRing createLinearRing4([List<Offset>? coordinates]) {
    if (coordinates == null) {
      return createLinearRings();
    }
    return createLinearRings(coordinates.map((e) => Coordinate.of2(e)).toList());
  }

  MultiPoint createMultiPoint([List<Point>? point]) => MultiPoint(point, this);

  MultiPoint createMultiPoint2([List<Coordinate>? coordinates]) {
    return createMultiPoint3(coordinates != null ? csFactory.create(coordinates) : null);
  }

  MultiPoint createMultiPoint3(CoordinateSequence? coordinates) {
    if (coordinates == null) {
      return createMultiPoint([]);
    }
    Array<Point> points = Array(coordinates.size());
    for (int i = 0; i < coordinates.size(); i++) {
      final ptSeq = csFactory.create4(1, coordinates.getDimension(), coordinates.getMeasures());
      CoordinateSequences.copy(coordinates, i, ptSeq, 0, 1);
      points[i] = createPoint3(ptSeq);
    }
    return createMultiPoint(points.toList());
  }

  MultiPoint createMultiPoint4(List<Coordinate>? coordinates) {
    return createMultiPoint3(coordinates != null ? csFactory.create(coordinates) : null);
  }

  MultiPoint createMultiPoint5([List<Offset>? point]) {
    if (point == null) {
      return createMultiPoint();
    }
    return createMultiPoint2(point.map((e) => Coordinate.of2(e)).toList());
  }

  Polygon createPolygon([LinearRing? shell, List<LinearRing>? holes]) => Polygon(shell, holes, this);

  Polygon createPolygon2(CoordinateSequence shell) {
    return createPolygon(createLinearRing2(shell));
  }

  Polygon createPolygon3(List<Coordinate> shell) {
    return createPolygon(createLinearRings(shell));
  }

  Polygon createPolygon4(List<Coordinate> vertexList, [bool close = true]) {
    List<Coordinate> array;
    if (close) {
      if (vertexList.first != vertexList.last) {
        array = [...vertexList, vertexList.first];
      } else {
        array = vertexList;
      }
    } else {
      array = vertexList;
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
      return createGeomCollection(geomList);
    }

    Geometry geom0 = geomList.first;
    bool isCollection = geomList.size > 1;
    if (isCollection) {
      if (geom0 is Polygon) {
        return createMultiPolygon(geomList.cast());
      } else if (geom0 is LineString) {
        return createMultiLineString(geomList.cast());
      } else if (geom0 is Point) {
        return createMultiPoint(geomList.cast());
      }
      Assert.shouldNeverReachHere("Unhandled class: ${geom0.runtimeType}");
    }
    return geom0;
  }

  LineString createLineString([CoordinateSequence? coordinates]) {
    final v = coordinates ?? csFactory.create([]);
    return LineString.of(v, this);
  }

  LineString createLineString2([List<Coordinate>? coordinates]) {
    return createLineString(coordinates != null ? csFactory.create(coordinates) : null);
  }

  LineString createLineString3([List<Offset>? coordinates]) {
    if (coordinates == null) {
      return createLineString2();
    }
    return createLineString2(coordinates.map((e) => Coordinate.of2(e)).toList());
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
