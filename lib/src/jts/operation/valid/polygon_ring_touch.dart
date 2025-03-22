import 'package:dts/src/jts/geom/coordinate.dart';

import 'polygon_ring.dart';

class PolygonRingTouch {
  final PolygonRing _ring;

  final Coordinate _touchPt;

  PolygonRingTouch(this._ring, this._touchPt);

  Coordinate getCoordinate() {
    return _touchPt;
  }

  PolygonRing getRing() {
    return _ring;
  }

  bool isAtLocation(Coordinate pt) {
    return _touchPt.equals2D(pt);
  }
}
