 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/operation/overlay/overlay_op.dart';

import 'snap_overlay_op.dart';

class SnapIfNeededOverlayOp {
  static Geometry? overlayOp(Geometry g0, Geometry g1, OverlayOpCode opCode) {
    return SnapIfNeededOverlayOp(g0, g1).getResultGeometry(opCode);
  }

  static Geometry? intersection(Geometry g0, Geometry g1) {
    return overlayOp(g0, g1, OverlayOpCode.intersection);
  }

  static Geometry? union(Geometry g0, Geometry g1) {
    return overlayOp(g0, g1, OverlayOpCode.union);
  }

  static Geometry? difference(Geometry g0, Geometry g1) {
    return overlayOp(g0, g1, OverlayOpCode.difference);
  }

  static Geometry? symDifference(Geometry g0, Geometry g1) {
    return overlayOp(g0, g1, OverlayOpCode.symDifference);
  }

  final Array<Geometry> _geom = Array(2);

  SnapIfNeededOverlayOp(Geometry g1, Geometry g2) {
    _geom[0] = g1;
    _geom[1] = g2;
  }

  Geometry? getResultGeometry(OverlayOpCode opCode) {
    Geometry? result;
    bool isSuccess = false;
    dynamic savedException;
    try {
      result = OverlayOp.overlayOp(_geom[0], _geom[1], opCode);
      bool isValid = true;
      if (isValid) {
        isSuccess = true;
      }
    } catch (ex) {
      savedException = ex;
    }
    if (!isSuccess) {
      try {
        result = SnapOverlayOp.overlayOp(_geom[0], _geom[1], opCode);
      } catch (ex) {
        throw savedException;
      }
    }
    return result;
  }
}
