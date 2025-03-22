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
    return !((((env.getMinX() > _polyEnv.getMaxX()) || (env.getMaxX() < _polyEnv.getMinX())) ||
            (env.getMinY() > _polyEnv.getMaxY())) ||
        (env.getMaxY() < _polyEnv.getMinY()));
  }

  bool _intersectsEnv(Coordinate p) {
    return !((((p.x > _polyEnv.getMaxX()) || (p.x < _polyEnv.getMinX())) || (p.y > _polyEnv.getMaxY())) ||
        (p.y < _polyEnv.getMinY()));
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
