class NumberUtil {
  static bool equalsWithTolerance(double x1, double x2, double tolerance) {
    return (x1 - x2).abs() <= tolerance;
  }
}
