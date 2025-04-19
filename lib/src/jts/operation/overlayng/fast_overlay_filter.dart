import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/operation/overlay/overlay_op.dart';

import 'overlay_util.dart';

class FastOverlayFilter {
  Geometry targetGeom;

  late bool _isTargetRectangle;

  FastOverlayFilter(this.targetGeom) {
    _isTargetRectangle = targetGeom.isRectangle();
  }

  Geometry? overlay(Geometry geom, OverlayOpCode overlayOpCode) {
    if (overlayOpCode != OverlayOpCode.intersection) return null;

    return intersection(geom);
  }

  Geometry? intersection(Geometry geom) {
    Geometry? resultForRect = intersectionRectangle(geom);
    if (resultForRect != null) return resultForRect;

    if (!isEnvelopeIntersects(targetGeom, geom)) {
      return createEmpty(geom);
    }
    return null;
  }

  Geometry createEmpty(Geometry geom) {
    return OverlayUtil.createEmptyResult(geom.getDimension(), geom.factory);
  }

  Geometry? intersectionRectangle(Geometry geom) {
    if (!_isTargetRectangle) return null;

    if (isEnvelopeCovers(targetGeom, geom)) {
      return geom.copy();
    }
    if (!isEnvelopeIntersects(targetGeom, geom)) {
      return createEmpty(geom);
    }
    return null;
  }

  bool isEnvelopeIntersects(Geometry a, Geometry b) {
    return a.getEnvelopeInternal().intersects(b.getEnvelopeInternal());
  }

  bool isEnvelopeCovers(Geometry a, Geometry b) {
    return a.getEnvelopeInternal().covers(b.getEnvelopeInternal());
  }
}
