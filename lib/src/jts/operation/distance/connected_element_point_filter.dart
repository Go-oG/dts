import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_filter.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';

class ConnectedElementPointFilter implements GeometryFilter {
  static List<Coordinate> getCoordinates(Geometry geom) {
    List<Coordinate> pts = [];
    geom.apply3(ConnectedElementPointFilter(pts));
    return pts;
  }

  List<Coordinate> pts;

  ConnectedElementPointFilter(this.pts);

  @override
  void filter(Geometry geom) {
    if (((geom is Point) || (geom is LineString)) || (geom is Polygon)) {
      pts.add(geom.getCoordinate()!);
    }
  }
}
