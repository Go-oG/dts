import 'package:dts/src/jts/geom/coordinate.dart';

class CoordinateCountFilter implements CoordinateFilter {
  int _n = 0;
  int getCount() => _n;

  @override
  void filter(Coordinate coord) {
    _n++;
  }
}
