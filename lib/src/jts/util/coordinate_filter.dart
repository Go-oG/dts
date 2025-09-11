import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

final class CoordinateArrayFilter implements CoordinateFilter {
  late final Array<Coordinate> pts;

  int _n = 0;

  CoordinateArrayFilter(int size) {
    pts = Array(size);
  }

  Array<Coordinate> getCoordinates() => pts;

  @override
  void filter(Coordinate coord) {
    pts[_n++] = coord;
  }
}

final class CoordinateCountFilter implements CoordinateFilter {
  int _n = 0;

  int getCount() => _n;

  @override
  void filter(Coordinate coord) {
    _n++;
  }
}

final class UniqueCoordinateArrayFilter implements CoordinateFilter {
  static List<Coordinate> filterCoordinates(List<Coordinate> coords) {
    final filter = UniqueCoordinateArrayFilter();
    for (int i = 0; i < coords.length; i++) {
      filter.filter(coords[i]);
    }
    return filter.getCoordinates();
  }

  final Set<Coordinate> _coordSet = <Coordinate>{};

  final List<Coordinate> _list = <Coordinate>[];

  List<Coordinate> getCoordinates() => _list;

  @override
  void filter(Coordinate coord) {
    if (_coordSet.add(coord)) {
      _list.add(coord);
    }
  }
}
