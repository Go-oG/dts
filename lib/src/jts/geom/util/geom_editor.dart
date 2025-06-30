import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_collection.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';
import 'package:dts/src/jts/geom/multi_point.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/util/assert.dart';

class GeometryEditor {
  GeomFactory? _factory;

  bool _isUserDataCopied = false;

  GeometryEditor.empty();

  GeometryEditor(this._factory);

  void setCopyUserData(bool isUserDataCopied) {
    _isUserDataCopied = isUserDataCopied;
  }

  Geometry? edit(Geometry? geometry, GeometryEditorOperation operation) {
    if (geometry == null) {
      return null;
    }

    Geometry? result = editInternal(geometry, operation);
    if (_isUserDataCopied) {
      result?.userData = geometry.userData;
    }
    return result;
  }

  Geometry? editInternal(Geometry geometry, GeometryEditorOperation operation) {
    _factory ??= geometry.factory;

    if (geometry is GeomCollection) {
      return editGeometryCollection(geometry, operation);
    }
    if (geometry is Polygon) {
      return editPolygon(geometry, operation);
    }
    if (geometry is Point) {
      return operation.edit(geometry, _factory!);
    }
    if (geometry is LineString) {
      return operation.edit(geometry, _factory!);
    }
    Assert.shouldNeverReachHere2("Unsupported Geometry class: ${geometry.runtimeType}");
    return null;
  }

  Polygon editPolygon(Polygon polygon, GeometryEditorOperation operation) {
    Polygon? newPolygon = (operation.edit(polygon, _factory!) as Polygon?);
    newPolygon ??= _factory!.createPolygon();

    if (newPolygon.isEmpty()) {
      return newPolygon;
    }
    LinearRing? shell = (edit(newPolygon.getExteriorRing(), operation) as LinearRing?);
    if ((shell == null) || shell.isEmpty()) {
      return _factory!.createPolygon();
    }
    List<LinearRing> holes = [];
    for (int i = 0; i < newPolygon.getNumInteriorRing(); i++) {
      LinearRing? hole = ((edit(newPolygon.getInteriorRingN(i), operation) as LinearRing?));
      if ((hole == null) || hole.isEmpty()) {
        continue;
      }
      holes.add(hole);
    }
    return _factory!.createPolygon(shell, holes.toArray());
  }

  GeomCollection editGeometryCollection(
      GeomCollection collection, GeometryEditorOperation operation) {
    GeomCollection collectionForType = (operation.edit(collection, _factory!) as GeomCollection);
    List<Geometry> geometries = [];
    for (int i = 0; i < collectionForType.getNumGeometries(); i++) {
      Geometry? geometry = edit(collectionForType.getGeometryN(i), operation);
      if ((geometry == null) || geometry.isEmpty()) {
        continue;
      }
      geometries.add(geometry);
    }
    if (collectionForType.runtimeType == MultiPoint) {
      return _factory!.createMultiPoint(geometries.cast<Point>().toArray());
    }
    if (collectionForType.runtimeType == MultiLineString) {
      return _factory!.createMultiLineString(geometries.cast<LineString>().toArray());
    }
    if (collectionForType.runtimeType == MultiPolygon) {
      return _factory!.createMultiPolygon(geometries.cast<Polygon>().toArray());
    }
    return _factory!.createGeomCollection(geometries.cast<Geometry>().toArray());
  }
}

abstract interface class GeometryEditorOperation {
  Geometry edit(Geometry geometry, GeomFactory factory);
}

abstract class CoordinateSequenceOperation implements GeometryEditorOperation {
  @override
  Geometry edit(Geometry geometry, GeomFactory factory) {
    if (geometry is LinearRing) {
      return factory.createLinearRing2(edit2(geometry.getCoordinateSequence(), geometry));
    }
    if (geometry is LineString) {
      return factory.createLineString(edit2(geometry.getCoordinateSequence(), geometry));
    }
    if (geometry is Point) {
      return factory.createPoint3(edit2(geometry.getCoordinateSequence(), geometry));
    }
    return geometry;
  }

  CoordinateSequence edit2(CoordinateSequence coordSeq, Geometry geometry);
}

class NoOpGeometryOperation implements GeometryEditorOperation {
  @override
  Geometry edit(Geometry geometry, GeomFactory factory) {
    return geometry;
  }
}

abstract class CoordinateOperation implements GeometryEditorOperation {
  @override
  Geometry edit(Geometry geometry, GeomFactory factory) {
    if (geometry is LinearRing) {
      return factory.createLinearRings(edit2(geometry.getCoordinates(), geometry));
    }
    if (geometry is LineString) {
      return factory.createLineString2(edit2(geometry.getCoordinates(), geometry));
    }
    if (geometry is Point) {
      final newCoordinates = edit2(geometry.getCoordinates(), geometry);
      return factory.createPoint2(
          newCoordinates != null && newCoordinates.length > 0 ? newCoordinates[0] : null);
    }
    return geometry;
  }

  Array<Coordinate>? edit2(Array<Coordinate> coordinates, Geometry geometry);
}
