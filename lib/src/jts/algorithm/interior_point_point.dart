import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_collection.dart';

import '../geom/point.dart';

final class InteriorPointPoint {
  static Coordinate? getInteriorPointS(Geometry geom) {
    InteriorPointPoint intPt = InteriorPointPoint(geom);
    return intPt.getInteriorPoint();
  }

  Coordinate? centroid;

  double minDistance = double.maxFinite;

  late Coordinate? interiorPoint;

  InteriorPointPoint(Geometry g) {
    centroid = g.getCentroid().getCoordinate();
    _add(g);
  }

  void _add(Geometry geom) {
    if (geom.isEmpty()) {
      return;
    }

    if (geom is Point) {
      _add2(geom.getCoordinate()!);
    } else if (geom is GeomCollection) {
      GeomCollection gc = (geom);
      for (int i = 0; i < gc.getNumGeometries(); i++) {
        _add(gc.getGeometryN(i));
      }
    }
  }

  void _add2(Coordinate point) {
    double dist = point.distance(centroid!);
    if (dist < minDistance) {
      interiorPoint = Coordinate.of(point);
      minDistance = dist;
    }
  }

  Coordinate? getInteriorPoint() {
    return interiorPoint;
  }
}
