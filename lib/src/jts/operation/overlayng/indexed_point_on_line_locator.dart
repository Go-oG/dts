import 'package:dts/src/jts/algorithm/point_locator.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';

class IndexedPointOnLineLocator implements PointOnGeometryLocator {
  Geometry inputGeom;

  IndexedPointOnLineLocator(this.inputGeom);

  @override
  int locate(Coordinate p) {
    PointLocator locator = PointLocator.empty();
    return locator.locate(p, inputGeom);
  }
}
