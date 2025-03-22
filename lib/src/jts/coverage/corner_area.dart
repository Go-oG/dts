 import 'dart:math';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/angle.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/triangle.dart';
import 'package:dts/src/jts/math/math.dart';

class CornerArea {
  static const double DEFAULT_SMOOTH_WEIGHT = 0.0;

  final double _smoothWeight;

  CornerArea([this._smoothWeight = DEFAULT_SMOOTH_WEIGHT]);

  double area(Coordinate pp, Coordinate p, Coordinate pn) {
    double area = Triangle.area2(pp, p, pn);
    double ang = _angleNorm(pp, p, pn);
    double angBias = 1.0 - (2.0 * ang);
    double areaWeighted = (1 - (_smoothWeight * angBias)) * area;
    return areaWeighted;
  }

  static double _angleNorm(Coordinate pp, Coordinate p, Coordinate pn) {
    double angNorm = (Angle.angleBetween(pp, p, pn) / 2) / pi;
    return MathUtil.clamp2(angNorm, 0, 1);
  }
}
