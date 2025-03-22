 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_string.dart';

final class InteriorPointLine {
  static Coordinate? getInteriorPointS(Geometry geom) {
    InteriorPointLine intPt = InteriorPointLine(geom);
    return intPt.interiorPoint;
  }

  late final Coordinate _centroid;

  double _minDistance = double.maxFinite;

  Coordinate? interiorPoint;

  InteriorPointLine(Geometry g) {
    _centroid = g.getCentroid().getCoordinate()!;
    _addInterior(g);

    if (interiorPoint == null) {
      _addEndpoints(g);
    }
  }

  void _addInterior(Geometry geom) {
    if (geom.isEmpty()) {
      return;
    }

    if (geom is LineString) {
      _addInterior2(geom.getCoordinates());
    } else if (geom is GeometryCollection) {
      GeometryCollection gc = (geom);
      for (int i = 0; i < gc.getNumGeometries(); i++) {
        _addInterior(gc.getGeometryN(i));
      }
    }
  }

  void _addInterior2(Array<Coordinate> pts) {
    for (int i = 1; i < (pts.length - 1); i++) {
      _add(pts[i]);
    }
  }

  void _addEndpoints(Geometry geom) {
    if (geom.isEmpty()) {
      return;
    }

    if (geom is LineString) {
      _addEndpoints2(geom.getCoordinates());
    } else if (geom is GeometryCollection) {
      GeometryCollection gc = (geom);
      for (int i = 0; i < gc.getNumGeometries(); i++) {
        _addEndpoints(gc.getGeometryN(i));
      }
    }
  }

  void _addEndpoints2(Array<Coordinate> pts) {
    _add(pts[0]);
    _add(pts[pts.length - 1]);
  }

  void _add(Coordinate point) {
    double dist = point.distance(_centroid);
    if (dist < _minDistance) {
      interiorPoint = Coordinate.of(point);
      _minDistance = dist;
    }
  }
}
