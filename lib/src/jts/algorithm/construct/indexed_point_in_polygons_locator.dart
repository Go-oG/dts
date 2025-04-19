import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/util/polygonal_extracter.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';

class IndexedPointInPolygonsLocator with InitMixin implements PointOnGeometryLocator {
  final Geometry _geom;
  late STRtree<IndexedPointInAreaLocator> _index;

  IndexedPointInPolygonsLocator(this._geom);

  void _init() {
    if (getAndMarkInit()) {
      return;
    }
    List<Geometry> polys = PolygonalExtracter.getPolygonals(_geom);
    _index = STRtree();
    for (int i = 0; i < polys.size; i++) {
      Geometry poly = polys.get(i);
      _index.insert(poly.getEnvelopeInternal(), IndexedPointInAreaLocator(poly));
    }
  }

  @override
  int locate(Coordinate p) {
    _init();
    List<IndexedPointInAreaLocator> results = _index.query(Envelope.fromCoordinate(p));
    for (var ptLocater in results) {
      int loc = ptLocater.locate(p);
      if (loc != Location.exterior) {
        return loc;
      }
    }
    return Location.exterior;
  }
}
