import 'geom.dart';

abstract interface class GeomComponentFilter {
  void filter(Geometry geom);
}

class GeomComponentFilter2 implements GeomComponentFilter {
  final void Function(Geometry geom) apply;

  GeomComponentFilter2(this.apply);

  @override
  void filter(Geometry geom) {
    apply.call(geom);
  }
}
