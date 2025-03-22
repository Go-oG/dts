import 'geometry.dart';

abstract interface class GeometryComponentFilter {
  void filter(Geometry geom);
}

class GeometryComponentFilter2 implements GeometryComponentFilter {
  final void Function(Geometry geom) apply;

  GeometryComponentFilter2(this.apply);

  @override
  void filter(Geometry geom) {
    apply.call(geom);
  }
}
