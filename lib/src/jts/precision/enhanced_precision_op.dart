import 'package:dts/src/jts/geom/geom.dart';

import 'common_bits_op.dart';

class EnhancedPrecisionOp {
  static Geometry? intersection(Geometry geom0, Geometry geom1) {
    dynamic originalEx;
    try {
      return geom0.intersection(geom1);
    } catch (e) {
      originalEx = e;
    }
    try {
      final cbo = CommonBitsOp(true);
      Geometry resultEP = cbo.intersection(geom0, geom1);
      if (!resultEP.isValid()) {
        throw originalEx;
      }

      return resultEP;
    } catch (ex2) {
      throw originalEx;
    }
  }

  static Geometry? union(Geometry geom0, Geometry geom1) {
    dynamic originalEx;
    try {
      return geom0.union2(geom1);
    } catch (ex) {
      originalEx = ex;
    }
    try {
      CommonBitsOp cbo = CommonBitsOp(true);
      Geometry resultEP = cbo.union(geom0, geom1);
      if (!resultEP.isValid()) {
        throw originalEx;
      }

      return resultEP;
    } catch (ex2) {
      throw originalEx;
    }
  }

  static Geometry? difference(Geometry geom0, Geometry geom1) {
    dynamic originalEx;
    try {
      return geom0.difference(geom1);
    } catch (ex) {
      originalEx = ex;
    }
    try {
      CommonBitsOp cbo = CommonBitsOp(true);
      Geometry resultEP = cbo.difference(geom0, geom1);
      if (!resultEP.isValid()) {
        throw originalEx;
      }

      return resultEP;
    } catch (ex2) {
      throw originalEx;
    }
  }

  static Geometry? symDifference(Geometry geom0, Geometry geom1) {
    dynamic originalEx;
    try {
      return geom0.symDifference(geom1);
    } catch (ex) {
      originalEx = ex;
    }
    try {
      CommonBitsOp cbo = CommonBitsOp(true);
      Geometry resultEP = cbo.symDifference(geom0, geom1);
      if (!resultEP.isValid()) {
        throw originalEx;
      }

      return resultEP;
    } catch (ex2) {
      throw originalEx;
    }
  }

  static Geometry buffer(Geometry geom, double distance) {
    dynamic originalEx;
    try {
      Geometry result = geom.buffer(distance);
      return result;
    } catch (ex) {
      originalEx = ex;
    }
    try {
      CommonBitsOp cbo = CommonBitsOp(true);
      Geometry resultEP = cbo.buffer(geom, distance);
      if (!resultEP.isValid()) {
        throw originalEx;
      }

      return resultEP;
    } catch (ex2) {
      throw originalEx;
    }
  }
}
