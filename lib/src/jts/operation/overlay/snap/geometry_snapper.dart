import 'dart:collection';
import 'dart:math';

import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/polygonal.dart';
import 'package:dts/src/jts/geom/precision_model.dart';

import 'snap_transformer.dart';

class GeometrySnapper {
  static const double _kSnapPrecisionFactor = 1.0E-9;

  static double computeOverlaySnapTolerance(Geometry g) {
    double snapTolerance = computeSizeBasedSnapTolerance(g);
    PrecisionModel pm = g.getPrecisionModel();
    if (pm.getType().isFixed) {
      double fixedSnapTol = ((1 / pm.getScale()) * 2) / 1.415;
      if (fixedSnapTol > snapTolerance) snapTolerance = fixedSnapTol;
    }
    return snapTolerance;
  }

  static double computeSizeBasedSnapTolerance(Geometry g) {
    Envelope env = g.getEnvelopeInternal();
    double minDimension = env.shortSide;
    double snapTol = minDimension * _kSnapPrecisionFactor;
    return snapTol;
  }

  static double computeOverlaySnapTolerance2(Geometry g0, Geometry g1) {
    return min(
        computeOverlaySnapTolerance(g0), computeOverlaySnapTolerance(g1));
  }

  static List<Geometry> snap(Geometry g0, Geometry g1, double snapTolerance) {
    GeometrySnapper snapper0 = GeometrySnapper(g0);
    Geometry rg1 = snapper0.snapTo(g1, snapTolerance)!;
    GeometrySnapper snapper1 = GeometrySnapper(g1);
    Geometry rg2 = snapper1.snapTo(rg1, snapTolerance)!;
    return [rg1, rg2];
  }

  static Geometry snapToSelf2(
      Geometry geom, double snapTolerance, bool cleanResult) {
    GeometrySnapper snapper0 = GeometrySnapper(geom);
    return snapper0.snapToSelf(snapTolerance, cleanResult);
  }

  final Geometry _srcGeom;

  GeometrySnapper(this._srcGeom);

  Geometry? snapTo(Geometry snapGeom, double snapTolerance) {
    List<Coordinate> snapPts = extractTargetCoordinates(snapGeom);
    final snapTrans = SnapTransformer(snapTolerance, snapPts);
    return snapTrans.transform(_srcGeom);
  }

  Geometry snapToSelf(double snapTolerance, bool cleanResult) {
    List<Coordinate> snapPts = extractTargetCoordinates(_srcGeom);
    final snapTrans = SnapTransformer(snapTolerance, snapPts, true);
    Geometry snappedGeom = snapTrans.transform(_srcGeom)!;
    Geometry result = snappedGeom;
    if (cleanResult && (result is Polygonal)) {
      result = snappedGeom.buffer(0);
    }
    return result;
  }

  List<Coordinate> extractTargetCoordinates(Geometry g) {
    Set<Coordinate> ptSet = SplayTreeSet();
    final pts = g.getCoordinates();
    for (int i = 0; i < pts.length; i++) {
      ptSet.add(pts[i]);
    }
    return ptSet.toList();
  }

  double computeSnapTolerance(List<Coordinate> ringPts) {
    double minSegLen = computeMinimumSegmentLength(ringPts);
    double snapTol = minSegLen / 10;
    return snapTol;
  }

  double computeMinimumSegmentLength(List<Coordinate> pts) {
    double minSegLen = double.maxFinite;
    for (int i = 0; i < (pts.length - 1); i++) {
      double segLen = pts[i].distance(pts[i + 1]);
      if (segLen < minSegLen) {
        minSegLen = segLen;
      }
    }
    return minSegLen;
  }
}
