import 'package:d_util/d_util.dart';

class CommonBits {
  static int signExpBits(int num) {
    return num >> 52;
  }

  static int numCommonMostSigMantissaBits(int num1, int num2) {
    int count = 0;
    for (int i = 52; i >= 0; i--) {
      if (getBit(num1, i) != getBit(num2, i)) {
        return count;
      }

      count++;
    }
    return 52;
  }

  static int zeroLowerBits(int bits, int nBits) {
    int invMask = (1 << nBits) - 1;
    int mask = ~invMask;
    int zeroed = bits & mask;
    return zeroed;
  }

  static int getBit(int bits, int i) {
    int mask = 1 << i;
    return (bits & mask) != 0 ? 1 : 0;
  }

  bool _isFirst = true;

  int _commonMantissaBitsCount = 53;

  int _commonBits = 0;

  int _commonSignExp = 0;

  void add(double num) {
    int numBits = Double.doubleToLongBits(num);
    if (_isFirst) {
      _commonBits = numBits;
      _commonSignExp = signExpBits(_commonBits);
      _isFirst = false;
      return;
    }
    int numSignExp = signExpBits(numBits);
    if (numSignExp != _commonSignExp) {
      _commonBits = 0;
      return;
    }
    _commonMantissaBitsCount =
        numCommonMostSigMantissaBits(_commonBits, numBits);
    _commonBits =
        zeroLowerBits(_commonBits, 64 - (12 + _commonMantissaBitsCount));
  }

  double getCommon() {
    return Double.doubleToLongBits(_commonBits.toDouble()).toDouble();
  }
}
