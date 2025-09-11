import 'dart:collection';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';

class VertexTaggedGeometryDataMapper {
  final Map<Coordinate, Object?> _coordDataMap = SplayTreeMap();

  void loadSourceGeometries(List<Geometry> geoms) {
    for (var i = geoms.iterator; i.moveNext();) {
      Geometry geom = i.current;
      loadVertices(geom.getCoordinates(), geom.userData);
    }
  }

  void loadSourceGeometries2(Geometry geomColl) {
    for (int i = 0; i < geomColl.getNumGeometries(); i++) {
      Geometry geom = geomColl.getGeometryN(i);
      loadVertices(geom.getCoordinates(), geom.userData);
    }
  }

  void loadVertices(List<Coordinate> pts, Object? data) {
    for (int i = 0; i < pts.length; i++) {
      _coordDataMap.put(pts[i], data);
    }
  }

  List<Coordinate> getCoordinates() => _coordDataMap.keys.toList();

  void transferData(Geometry targetGeom) {
    for (int i = 0; i < targetGeom.getNumGeometries(); i++) {
      Geometry geom = targetGeom.getGeometryN(i);
      final Coordinate? vertexKey = geom.userData;
      if (vertexKey == null) continue;
      geom.userData = _coordDataMap.get(vertexKey);
    }
  }
}
