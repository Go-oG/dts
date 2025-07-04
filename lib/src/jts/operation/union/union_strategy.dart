import 'package:dts/src/jts/geom/geometry.dart';

abstract interface class UnionStrategy {
  Geometry? union(Geometry g0, Geometry g1);

  bool isDoublePrecision();
}
