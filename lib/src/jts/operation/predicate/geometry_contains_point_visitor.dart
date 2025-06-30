import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/util/short_circuited_geometry_visitor.dart';

class GeometryContainsPointVisitor extends ShortCircuitedGeometryVisitor {
  late CoordinateSequence _rectSeq;

  late Envelope rectEnv;

  bool _containsPoint = false;

  GeometryContainsPointVisitor(Polygon rectangle) {
    _rectSeq = rectangle.getExteriorRing().getCoordinateSequence();
    rectEnv = rectangle.getEnvelopeInternal();
  }

  bool containsPoint() {
    return _containsPoint;
  }

  @override
  void visit(Geometry geom) {
    if (geom is! Polygon) {
      return;
    }

    Envelope elementEnv = geom.getEnvelopeInternal();
    if (!rectEnv.intersects(elementEnv)) {
      return;
    }

    Coordinate rectPt = Coordinate();
    for (int i = 0; i < 4; i++) {
      _rectSeq.getCoordinate2(i, rectPt);
      if (!elementEnv.containsCoordinate(rectPt)) {
        continue;
      }

      if (SimplePointInAreaLocator.containsPointInPolygon(rectPt, geom)) {
        _containsPoint = true;
        return;
      }
    }
  }

  @override
  bool isDone() {
    return _containsPoint;
  }
}
