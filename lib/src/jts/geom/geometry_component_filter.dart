import 'geometry.dart';

abstract interface class GeometryComponentFilter {
  void filter(Geometry geom);
}

class GeomComponentFilter2 implements GeometryComponentFilter {
  final void Function(Geometry geom) apply;

  GeomComponentFilter2(this.apply);

  @override
  void filter(Geometry geom) {
    apply.call(geom);
  }
}
