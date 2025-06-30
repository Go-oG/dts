import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_collection.dart';

abstract class ShortCircuitedGeometryVisitor {
  bool _isDone = false;

  ShortCircuitedGeometryVisitor();

  void applyTo(Geometry geom) {
    for (int i = 0; (i < geom.getNumGeometries()) && (!_isDone); i++) {
      Geometry element = geom.getGeometryN(i);
      if (element is! GeomCollection) {
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
