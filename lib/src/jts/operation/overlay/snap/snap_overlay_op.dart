import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/operation/overlay/overlay_op.dart';
import 'package:dts/src/jts/precision/common_bits_remover.dart';

import 'geometry_snapper.dart';

class SnapOverlayOp {
  static Geometry? overlayOp(Geometry g0, Geometry g1, OverlayOpCode opCode) {
    SnapOverlayOp op = SnapOverlayOp(g0, g1);
    return op.getResultGeometry(opCode);
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

  Array<Geometry> geom = Array(2);
  double snapTolerance = 0;
  late CommonBitsRemover _cbr;

  SnapOverlayOp(Geometry g1, Geometry g2) {
    geom[0] = g1;
    geom[1] = g2;
    computeSnapTolerance();
  }

  void computeSnapTolerance() {
    snapTolerance = GeometrySnapper.computeOverlaySnapTolerance2(geom[0], geom[1]);
  }

  Geometry? getResultGeometry(OverlayOpCode opCode) {
    Array<Geometry> prepGeom = snap(geom);
    Geometry result = OverlayOp.overlayOp(prepGeom[0], prepGeom[1], opCode);
    return prepareResult(result);
  }

  Geometry? selfSnap(Geometry geom) {
    final snapper0 = GeometrySnapper(geom);
    return snapper0.snapTo(geom, snapTolerance);
  }

  Array<Geometry> snap(Array<Geometry> geom) {
    Array<Geometry> remGeom = removeCommonBits(geom);
    Array<Geometry> snapGeom = GeometrySnapper.snap(remGeom[0], remGeom[1], snapTolerance);
    return snapGeom;
  }

  Geometry prepareResult(Geometry geom) {
    _cbr.addCommonBits(geom);
    return geom;
  }

  Array<Geometry> removeCommonBits(Array<Geometry> geom) {
    _cbr = CommonBitsRemover();
    _cbr.add(geom[0]);
    _cbr.add(geom[1]);
    Array<Geometry> remGeom = Array(2);
    remGeom[0] = _cbr.removeCommonBits(geom[0].copy());
    remGeom[1] = _cbr.removeCommonBits(geom[1].copy());
    return remGeom;
  }
}
