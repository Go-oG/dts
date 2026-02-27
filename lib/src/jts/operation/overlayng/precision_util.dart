import 'dart:math';

import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/math/math.dart';

class PrecisionUtil {
  static int kMaxRobustDpDigits = 14;

  static PrecisionModel robustPM2(Geometry a, Geometry b) {
    double scale = PrecisionUtil.robustScale2(a, b);
    return PrecisionModel.fixed(scale);
  }

  static double safeScale(double value) {
    return precisionScale(value, kMaxRobustDpDigits);
  }

  static double safeScale2(Geometry geom) {
    return safeScale(maxBoundMagnitude(geom.getEnvelopeInternal()));
  }

  static double safeScale3(Geometry a, Geometry? b) {
    double maxBnd = maxBoundMagnitude(a.getEnvelopeInternal());
    if (b != null) {
      double maxBndB = maxBoundMagnitude(b.getEnvelopeInternal());
      maxBnd = max(maxBnd, maxBndB);
    }
    double scale = PrecisionUtil.safeScale(maxBnd);
    return scale;
  }

  static double maxBoundMagnitude(Envelope env) {
    return MathUtil.max2(
      env.maxX.abs(),
      env.maxY.abs(),
      env.minX.abs(),
      env.minY.abs(),
    );
  }

  static double precisionScale(double value, int precisionDigits) {
    int magnitude = ((log(value) / log(10)) + 1.0).toInt();
    int precDigits = precisionDigits - magnitude;
    return pow(10.0, precDigits).toDouble();
  }

  static double inherentScale(double value) {
    int numDec = numberOfDecimals(value);
    return pow(10.0, numDec).toDouble();
  }

  static double inherentScale2(Geometry geom) {
    final scaleFilter = _InherentScaleFilter();
    geom.apply(scaleFilter);
    return scaleFilter.getScale();
  }

  static double inherentScale3(Geometry a, Geometry? b) {
    double scale = PrecisionUtil.inherentScale2(a);
    if (b != null) {
      double scaleB = PrecisionUtil.inherentScale2(b);
      scale = max(scale, scaleB);
    }
    return scale;
  }

  static int numberOfDecimals(double value) {
    String s = value.toStringAsFixed(1);
    if (s.endsWith(".0")) {
      return 0;
    }
    int len = s.length;
    int decIndex = s.indexOf('.');
    if (decIndex <= 0) {
      return 0;
    }

    return (len - decIndex) - 1;
  }

  static PrecisionModel robustPM(Geometry a) {
    double scale = PrecisionUtil.robustScale(a);
    return PrecisionModel.fixed(scale);
  }

  static double robustScale2(Geometry a, Geometry b) {
    double inherentScale = inherentScale3(a, b);
    double safeScale = safeScale3(a, b);
    return robustScale3(inherentScale, safeScale);
  }

  static double robustScale(Geometry a) {
    double inherentScale = inherentScale2(a);
    double safeScale = safeScale2(a);
    return robustScale3(inherentScale, safeScale);
  }

  static double robustScale3(double inherentScale, double safeScale) {
    if (inherentScale <= safeScale) {
      return inherentScale;
    }
    return safeScale;
  }
}

class _InherentScaleFilter implements CoordinateFilter {
  double _scale = 0;

  double getScale() {
    return _scale;
  }

  @override
  void filter(Coordinate coord) {
    updateScaleMax(coord.x);
    updateScaleMax(coord.y);
  }

  void updateScaleMax(double value) {
    double scaleVal = PrecisionUtil.inherentScale(value);
    if (scaleVal > _scale) {
      _scale = scaleVal;
    }
  }
}
