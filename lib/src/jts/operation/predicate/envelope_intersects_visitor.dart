import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
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
    if (!rectEnv.intersects6(elementEnv)) {
            return;
        }
        if (rectEnv.contains3(elementEnv)) {
            _intersects = true;
            return;
        }
        if ((elementEnv.getMinX() >= rectEnv.getMinX()) && (elementEnv.getMaxX() <= rectEnv.getMaxX())) {
            _intersects = true;
            return;
        }
        if ((elementEnv.getMinY() >= rectEnv.getMinY()) && (elementEnv.getMaxY() <= rectEnv.getMaxY())) {
            _intersects = true;
            return;
        }
    }

  @override
  bool isDone() {
    return _intersects;
  }
}
