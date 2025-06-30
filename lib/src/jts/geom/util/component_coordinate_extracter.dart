import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_component_filter.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/point.dart';

class ComponentCoordinateExtracter implements GeomComponentFilter {
  static List<Coordinate> getCoordinates(Geometry geom) {
    List<Coordinate> coords = [];
    geom.apply4(ComponentCoordinateExtracter(coords));
    return coords;
  }

  final List<Coordinate> _coords;

  ComponentCoordinateExtracter(this._coords);

  @override
  void filter(Geometry geom) {
    if (geom.isEmpty()) {
      return;
    }

    if ((geom is LineString) || (geom is Point)) {
      _coords.add(geom.getCoordinate()!);
    }
  }
}
