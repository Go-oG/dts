import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

class CoordinateArrayFilter implements CoordinateFilter {
  late final Array<Coordinate> pts;

  int n = 0;

  CoordinateArrayFilter(int size) {
    pts = Array(size);
  }

  Array<Coordinate> getCoordinates() {
    return pts;
  }

  @override
  void filter(Coordinate coord) {
    pts[n++] = coord;
  }
}
