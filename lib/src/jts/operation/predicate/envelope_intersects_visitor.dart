import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/util/short_circuited_geometry_visitor.dart';

class EnvelopeIntersectsVisitor extends ShortCircuitedGeometryVisitor {
  Envelope rectEnv;
  bool _intersects = false;

  EnvelopeIntersectsVisitor(this.rectEnv);

  bool intersects() {
    return _intersects;
  }

  @override
  void visit(Geometry element) {
    Envelope elementEnv = element.getEnvelopeInternal();
    if (!rectEnv.intersects(elementEnv)) {
      return;
    }
    if (rectEnv.contains(elementEnv)) {
      _intersects = true;
      return;
    }
    if ((elementEnv.minX >= rectEnv.minX) && (elementEnv.maxX <= rectEnv.maxX)) {
      _intersects = true;
      return;
    }
    if ((elementEnv.minY >= rectEnv.minY) && (elementEnv.maxY <= rectEnv.maxY)) {
      _intersects = true;
      return;
    }
  }

  @override
  bool isDone() {
    return _intersects;
  }
}
