import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/noding/snap/snapping_noder.dart';
import 'package:dts/src/jts/operation/union/unary_union_op.dart';
import 'package:dts/src/jts/operation/union/union_strategy.dart';

import '../overlay/overlay_op.dart';
import 'overlay_ng.dart';
import 'precision_util.dart';

class OverlayNGRobust {
  static const double _snapTolFactor = 1.0E12;
  static const int _numSnapTries = 5;

  static Geometry? union(Geometry geom) {
    UnaryUnionOp op = UnaryUnionOp.of(geom);
    op.setUnionFunction(_overlayUnion);
    return op.union();
  }

  static Geometry? union2(List<Geometry> geoms) {
    UnaryUnionOp op = UnaryUnionOp(geoms);
    op.setUnionFunction(_overlayUnion);
    return op.union();
  }

  static Geometry? union3(List<Geometry> geoms, GeomFactory geomFact) {
    UnaryUnionOp op = UnaryUnionOp(geoms, geomFact);
    op.setUnionFunction(_overlayUnion);
    return op.union();
  }

  static final _overlayUnion = _UnionStrategy();

  static Geometry overlay(Geometry geom0, Geometry geom1, OverlayOpCode opCode) {
    Geometry? result;
    dynamic exOriginal;
    try {
      result = OverlayNG.overlay(geom0, geom1, opCode);
      return result;
    } catch (ex) {
      exOriginal = ex;
    }
    result = overlaySnapTries(geom0, geom1, opCode);
    if (result != null) return result;

    result = overlaySR(geom0, geom1, opCode);
    if (result != null) return result;

    throw exOriginal;
  }

  static Geometry? overlaySnapTries(Geometry geom0, Geometry geom1, OverlayOpCode opCode) {
    Geometry? result;
    double snapTol = snapTolerance2(geom0, geom1);
    for (int i = 0; i < _numSnapTries; i++) {
      result = overlaySnapping(geom0, geom1, opCode, snapTol);
      if (result != null) return result;

      result = overlaySnapBoth(geom0, geom1, opCode, snapTol);
      if (result != null) return result;

      snapTol = snapTol * 10;
    }
    return null;
  }

  static Geometry? overlaySnapping(
      Geometry geom0, Geometry geom1, OverlayOpCode opCode, double snapTol) {
    try {
      return overlaySnapTol(geom0, geom1, opCode, snapTol);
    } catch (ex) {}
    return null;
  }

  static Geometry? overlaySnapBoth(
      Geometry geom0, Geometry geom1, OverlayOpCode opCode, double snapTol) {
    try {
      Geometry snap0 = snapSelf(geom0, snapTol);
      Geometry snap1 = snapSelf(geom1, snapTol);
      return overlaySnapTol(snap0, snap1, opCode, snapTol);
    } catch (ex) {}
    return null;
  }

  static Geometry snapSelf(Geometry geom, double snapTol) {
    final ov = OverlayNG.of(geom, null);
    SnappingNoder snapNoder = SnappingNoder(snapTol);
    ov.setNoder(snapNoder);
    ov.setStrictMode(true);
    return ov.getResult();
  }

  static Geometry overlaySnapTol(
      Geometry geom0, Geometry geom1, OverlayOpCode opCode, double snapTol) {
    SnappingNoder snapNoder = SnappingNoder(snapTol);
    return OverlayNG.overlay2(geom0, geom1, opCode, snapNoder);
  }

  static double snapTolerance2(Geometry geom0, Geometry geom1) {
    double tol0 = snapTolerance(geom0);
    double tol1 = snapTolerance(geom1);
    return Math.maxD(tol0, tol1);
  }

  static double snapTolerance(Geometry geom) {
    double magnitude = ordinateMagnitude(geom);
    return magnitude / _snapTolFactor;
  }

  static double ordinateMagnitude(Geometry? geom) {
    if ((geom == null) || geom.isEmpty()) return 0;

    Envelope env = geom.getEnvelopeInternal();
    double magMax = Math.maxD(Math.abs(env.maxX), Math.abs(env.maxY));
    double magMin = Math.maxD(Math.abs(env.minX), Math.abs(env.minY));
    return Math.maxD(magMax, magMin);
  }

  static Geometry? overlaySR(Geometry geom0, Geometry geom1, OverlayOpCode opCode) {
    Geometry result;
    try {
      double scaleSafe = PrecisionUtil.safeScale3(geom0, geom1);
      PrecisionModel pmSafe = PrecisionModel.fixed(scaleSafe);
      result = OverlayNG.overlay3(geom0, geom1, opCode, pmSafe);
      return result;
    } catch (ex) {}
    return null;
  }
}

class _UnionStrategy implements UnionStrategy {
  @override
  Geometry union(Geometry g0, Geometry g1) {
    return OverlayNGRobust.overlay(g0, g1, OverlayOpCode.union);
  }

  @override
  bool isdoubleingPrecision() {
    return true;
  }
}
