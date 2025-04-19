import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/polygon.dart';

class CoveragePolygon {
  Polygon polygon;

  late Envelope _polyEnv;

  IndexedPointInAreaLocator? locator;

  CoveragePolygon(this.polygon) {
    _polyEnv = polygon.getEnvelopeInternal();
  }

  bool intersectsEnv(Envelope env) {
    return !((((env.minX > _polyEnv.maxX) || (env.maxX < _polyEnv.minX)) ||
            (env.minY > _polyEnv.maxY)) ||
        (env.maxY < _polyEnv.minY));
  }

  bool _intersectsEnv(Coordinate p) {
    return !((((p.x > _polyEnv.maxX) || (p.x < _polyEnv.minX)) || (p.y > _polyEnv.maxY)) ||
        (p.y < _polyEnv.minY));
  }

  bool contains(Coordinate p) {
    if (!_intersectsEnv(p)) {
      return false;
    }

    PointOnGeometryLocator pia = _getLocator();
    return Location.interior == pia.locate(p);
  }

  PointOnGeometryLocator _getLocator() {
    locator ??= IndexedPointInAreaLocator(polygon);
    return locator!;
  }
}
