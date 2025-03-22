import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';

abstract class ShortCircuitedGeometryVisitor {
  bool _isDone = false;

  ShortCircuitedGeometryVisitor();

  void applyTo(Geometry geom) {
    for (int i = 0; (i < geom.getNumGeometries()) && (!_isDone); i++) {
      Geometry element = geom.getGeometryN(i);
      if (element is! GeometryCollection) {
        visit(element);
        if (isDone()) {
          _isDone = true;
          return;
        }
      } else {
        applyTo(element);
      }
    }
  }

  void visit(Geometry element);

  bool isDone();
}
