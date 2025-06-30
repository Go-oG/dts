import 'package:d_util/d_util.dart';

import '../coordinate.dart';
import '../coordinate_sequence.dart';
import '../geom.dart';
import '../geom_collection.dart';
import '../geom_factory.dart';
import '../line_string.dart';
import '../linear_ring.dart';
import '../multi_line_string.dart';
import '../multi_point.dart';
import '../multi_polygon.dart';
import '../point.dart';
import '../polygon.dart';

class GeometryTransformer {
  late Geometry inputGeom;

  late GeomFactory factory;

  final bool _pruneEmptyGeometry = true;
  final bool _preserveGeometryCollectionType = true;
  final bool _preserveType = false;

  GeometryTransformer();

  Geometry getInputGeometry() {
    return inputGeom;
  }

  Geometry? transform(Geometry inputGeom) {
    this.inputGeom = inputGeom;
    factory = inputGeom.factory;
    if (inputGeom is Point) return transformPoint(inputGeom, null);

    if (inputGeom is MultiPoint) return transformMultiPoint(inputGeom, null);

    if (inputGeom is LinearRing) return transformLinearRing(inputGeom, null);

    if (inputGeom is LineString) return transformLineString(inputGeom, null);

    if (inputGeom is MultiLineString) return transformMultiLineString(inputGeom, null);

    if (inputGeom is Polygon) return transformPolygon(inputGeom, null);

    if (inputGeom is MultiPolygon) return transformMultiPolygon(inputGeom, null);

    if (inputGeom is GeomCollection) return transformGeometryCollection(inputGeom, null);

    throw IllegalArgumentException("Unknown Geometry subtype: ${inputGeom.runtimeType}");
  }

  CoordinateSequence createCoordinateSequence(Array<Coordinate> coords) {
    return factory.csFactory.create(coords);
  }

  CoordinateSequence copy(CoordinateSequence seq) {
    return seq.copy();
  }

  CoordinateSequence? transformCoordinates(CoordinateSequence coords, Geometry? parent) {
    return copy(coords);
  }

  Geometry? transformPoint(Point geom, Geometry? parent) {
    return factory.createPoint3(transformCoordinates(geom.getCoordinateSequence(), geom)!);
  }

  Geometry transformMultiPoint(MultiPoint geom, Geometry? parent) {
    List<Geometry> transGeomList = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      final transformGeom = transformPoint(geom.getGeometryN(i), geom);
      if (transformGeom == null) continue;

      if (transformGeom.isEmpty()) continue;

      transGeomList.add(transformGeom);
    }
    if (transGeomList.isEmpty) {
      return factory.createMultiPoint();
    }
    return factory.buildGeometry(transGeomList);
  }

  Geometry? transformLinearRing(LinearRing geom, Geometry? parent) {
    final seq = transformCoordinates(geom.getCoordinateSequence(), geom);
    if (seq == null) return factory.createLinearRing2(null);

    int seqSize = seq.size();
    if (((seqSize > 0) && (seqSize < 4)) && (!_preserveType)) return factory.createLineString(seq);

    return factory.createLinearRing2(seq);
  }

  Geometry? transformLineString(LineString geom, Geometry? parent) {
    return factory.createLineString(transformCoordinates(geom.getCoordinateSequence(), geom)!);
  }

  Geometry transformMultiLineString(MultiLineString geom, Geometry? parent) {
    List<Geometry> transGeomList = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      final transformGeom = transformLineString(geom.getGeometryN(i), geom);
      if (transformGeom == null) continue;

      if (transformGeom.isEmpty()) continue;

      transGeomList.add(transformGeom);
    }
    if (transGeomList.isEmpty) {
      return factory.createMultiLineString();
    }
    return factory.buildGeometry(transGeomList);
  }

  Geometry? transformPolygon(Polygon geom, Geometry? parent) {
    bool isAllValidLinearRings = true;
    Geometry? shell = transformLinearRing(geom.getExteriorRing(), geom);
    bool shellIsNullOrEmpty = (shell == null) || shell.isEmpty();
    if (geom.isEmpty() && shellIsNullOrEmpty) {
      return factory.createPolygon();
    }
    if (shellIsNullOrEmpty || (shell is! LinearRing)) {
      isAllValidLinearRings = false;
    }

    List<Geometry> holes = [];
    for (int i = 0; i < geom.getNumInteriorRing(); i++) {
      final hole = transformLinearRing(geom.getInteriorRingN(i), geom);
      if ((hole == null) || hole.isEmpty()) {
        continue;
      }
      if (hole is! LinearRing) {
        isAllValidLinearRings = false;
      }
      holes.add(hole);
    }
    if (isAllValidLinearRings) {
      return factory.createPolygon(shell as LinearRing, Array());
    } else {
      List<Geometry> components = [];
      if (shell != null) {
        components.add(shell);
      }
      components.addAll(holes);
      return factory.buildGeometry(components);
    }
  }

  Geometry transformMultiPolygon(MultiPolygon geom, Geometry? parent) {
    List<Geometry> transGeomList = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry? transformGeom = transformPolygon(geom.getGeometryN(i), geom);
      if (transformGeom == null) continue;

      if (transformGeom.isEmpty()) continue;

      transGeomList.add(transformGeom);
    }
    if (transGeomList.isEmpty) {
      return factory.createMultiPolygon();
    }
    return factory.buildGeometry(transGeomList);
  }

  Geometry? transformGeometryCollection(GeomCollection geom, Geometry? parent) {
    List<Geometry> transGeomList = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry? transformGeom = transform(geom.getGeometryN(i));
      if (transformGeom == null) {
        continue;
      }

      if (_pruneEmptyGeometry && transformGeom.isEmpty()) {
        continue;
      }
      transGeomList.add(transformGeom);
    }
    if (_preserveGeometryCollectionType) {
      return factory.createGeomCollection(GeomFactory.toGeometryArray(transGeomList)!);
    }
    return factory.buildGeometry(transGeomList);
  }
}
