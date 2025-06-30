import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/geom.dart';

import 'common_bits_remover.dart';

class CommonBitsOp {
  final bool _returnToOriginalPrecision;

  late CommonBitsRemover cbr;

  CommonBitsOp([this._returnToOriginalPrecision = true]);

  Geometry intersection(Geometry geom0, Geometry geom1) {
    Array<Geometry> geom = removeCommonBits2(geom0, geom1);
    return computeResultPrecision(geom[0].intersection(geom[1])!);
  }

  Geometry union(Geometry geom0, Geometry geom1) {
    Array<Geometry> geom = removeCommonBits2(geom0, geom1);
    return computeResultPrecision(geom[0].union2(geom[1])!);
  }

  Geometry difference(Geometry geom0, Geometry geom1) {
    Array<Geometry> geom = removeCommonBits2(geom0, geom1);
    return computeResultPrecision(geom[0].difference(geom[1])!);
  }

  Geometry symDifference(Geometry geom0, Geometry geom1) {
    Array<Geometry> geom = removeCommonBits2(geom0, geom1);
    return computeResultPrecision(geom[0].symDifference(geom[1])!);
  }

  Geometry buffer(Geometry geom0, double distance) {
    Geometry geom = removeCommonBits(geom0);
    return computeResultPrecision(geom.buffer(distance));
  }

  Geometry computeResultPrecision(Geometry result) {
    if (_returnToOriginalPrecision) {
      cbr.addCommonBits(result);
    }

    return result;
  }

  Geometry removeCommonBits(Geometry geom0) {
    cbr = CommonBitsRemover();
    cbr.add(geom0);
    return cbr.removeCommonBits(geom0.copy());
  }

  Array<Geometry> removeCommonBits2(Geometry geom0, Geometry geom1) {
    cbr = CommonBitsRemover();
    cbr.add(geom0);
    cbr.add(geom1);
    Array<Geometry> geom = Array(2);
    geom[0] = cbr.removeCommonBits(geom0.copy());
    geom[1] = cbr.removeCommonBits(geom1.copy());
    return geom;
  }
}
