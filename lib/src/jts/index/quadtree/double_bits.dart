 import 'package:d_util/d_util.dart';

class DoubleBits {
  static const int EXPONENT_BIAS = 1023;

  static double powerOf2(int exp) {
    if ((exp > 1023) || (exp < (-1022))) {
      throw ("Exponent out of bounds");
    }
    int expBias = exp + EXPONENT_BIAS;
    int bits = expBias << 52;
    return Double.longBitsToDouble(bits);
  }

  static int exponent(double d) {
    DoubleBits db = DoubleBits(d);
    return db.getExponent();
  }

  static double truncateToPowerOfTwo(double d) {
    DoubleBits db = DoubleBits(d);
    db.zeroLowerBits(52);
    return db.getDouble();
  }

  static String toBinaryString(double d) {
    DoubleBits db = DoubleBits(d);
    return db.toString();
  }

  static double maximumCommonMantissa(double d1, double d2) {
    if ((d1 == 0.0) || (d2 == 0.0)) {
      return 0.0;
    }

    DoubleBits db1 = DoubleBits(d1);
    DoubleBits db2 = DoubleBits(d2);
    if (db1.getExponent() != db2.getExponent()) {
      return 0.0;
    }

    int maxCommon = db1.numCommonMantissaBits(db2);
    db1.zeroLowerBits(64 - (12 + maxCommon));
    return db1.getDouble();
  }

  double x;

  late int _xBits;

  DoubleBits(this.x) {
    _xBits = Double.doubleToLongBits(x);
  }

  double getDouble() {
    return Double.longBitsToDouble(_xBits);
  }

  int biasedExponent() {
    int signExp = ((_xBits >> 52));
    int exp = signExp & 0x7ff;
    return exp;
  }

  int getExponent() {
    return biasedExponent() - EXPONENT_BIAS;
  }

  void zeroLowerBits(int nBits) {
    int invMask = (1 << nBits) - 1;
    int mask = ~invMask;
    _xBits &= mask;
  }

  int getBit(int i) {
    int mask = 1 << i;
    return (_xBits & mask) != 0 ? 1 : 0;
  }

  int numCommonMantissaBits(DoubleBits db) {
    for (int i = 0; i < 52; i++) {
      if (getBit(i) != db.getBit(i)) {
        return i;
      }
    }
    return 52;
  }
}
