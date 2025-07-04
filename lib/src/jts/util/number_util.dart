import 'package:d_util/d_util.dart';

class NumberUtil {
  static bool equalsWithTolerance(double x1, double x2, double tolerance) {
    return Math.abs(x1 - x2) <= tolerance;
  }
}
