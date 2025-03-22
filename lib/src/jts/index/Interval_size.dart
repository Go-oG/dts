class IntervalSize {
  static bool isZeroWidth(double min, double max) {
    return (max - min).abs() <= 0.000000000001;
  }
}
