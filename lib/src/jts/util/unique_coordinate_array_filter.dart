import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

class UniqueCoordinateArrayFilter implements CoordinateFilter {
  static Array<Coordinate> filterCoordinates(Array<Coordinate> coords) {
    UniqueCoordinateArrayFilter filter = UniqueCoordinateArrayFilter();
    for (int i = 0; i < coords.length; i++) {
      filter.filter(coords[i]);
    }
    return filter.getCoordinates();
  }

  final Set<Coordinate> _coordSet = <Coordinate>{};

  final List<Coordinate> _list = <Coordinate>[];

  UniqueCoordinateArrayFilter();

  Array<Coordinate> getCoordinates() {
    return Array.list(_list);
  }

  @override
  void filter(Coordinate coord) {
    if (_coordSet.add(coord)) {
      _list.add(coord);
    }
  }
}
