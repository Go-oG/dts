import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_filter.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'geometry_location.dart';

class ConnectedElementLocationFilter implements GeomFilter {
  static List<GeometryLocation> getLocations(Geometry geom) {
    List<GeometryLocation> locations = [];
    geom.apply3(ConnectedElementLocationFilter(locations));
    return locations;
  }

  final List<GeometryLocation> _locations;

  ConnectedElementLocationFilter(this._locations);

  @override
  void filter(Geometry geom) {
    if (geom.isEmpty()) return;

    if (((geom is Point) || (geom is LineString)) || (geom is Polygon)) {
      _locations.add(GeometryLocation(geom, 0, geom.getCoordinate()!));
    }
  }
}
