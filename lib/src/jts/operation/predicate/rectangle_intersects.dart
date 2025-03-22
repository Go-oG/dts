import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'envelope_intersects_visitor.dart';
import 'geometry_contains_point_visitor.dart';
import 'rectangle_intersects_segment_visitor.dart';

class RectangleIntersects {
  static bool intersects2(Polygon rectangle, Geometry b) {
        RectangleIntersects rp = RectangleIntersects(rectangle);
        return rp.intersects(b);
    }

  final Polygon _rectangle;

  late Envelope rectEnv;

  RectangleIntersects(this._rectangle) {
    rectEnv = _rectangle.getEnvelopeInternal();
  }

  bool intersects(Geometry geom) {
    if (!rectEnv.intersects6(geom.getEnvelopeInternal())) {
      return false;
    }

    final visitor = EnvelopeIntersectsVisitor(rectEnv);
      visitor.applyTo(geom);
      if (visitor.intersects()) {
        return true;
      }

    final ecpVisitor = GeometryContainsPointVisitor(_rectangle);
    ecpVisitor.applyTo(geom);
    if (ecpVisitor.containsPoint()) {
      return true;
    }

    final riVisitor = RectangleIntersectsSegmentVisitor(_rectangle);
      riVisitor.applyTo(geom);
      if (riVisitor.intersects()) {
        return true;
      }

        return false;
    }
}
