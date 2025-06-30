import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_filter.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';

class PolygonalLineworkExtracter implements GeomFilter {
  final List<LinearRing> _linework = [];

  @override
  void filter(Geometry g) {
    if (g is Polygon) {
      _linework.add(g.getExteriorRing());
      for (int i = 0; i < g.getNumInteriorRing(); i++) {
        _linework.add(g.getInteriorRingN(i));
      }
    }
  }

  List<LinearRing> getLinework() {
    return _linework;
  }
}
