import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

class MortonCode {
  static const int kMaxLevel = 16;

  static int size(int level) {
    checkLevel(level);
    return Math.pow(2, 2 * level.toDouble()).toInt();
  }

  static int maxOrdinate(int level) {
    checkLevel(level);
    return (Math.pow(2, level.toDouble()).toInt()) - 1;
  }

  static int level(int numPoints) {
    int pow2 = (Math.log(numPoints.toDouble()) / Math.log(2)).toInt();
    int level = pow2 ~/ 2;
    int sizeV = size(level);
    if (sizeV < numPoints) {
      level += 1;
    }

    return level;
  }

  static void checkLevel(int level) {
    if (level > kMaxLevel) {
      throw IllegalArgumentException("Level must be in range 0 to $kMaxLevel");
    }
  }

  static int encode(int x, int y) {
    return (interleave(y) << 1) + interleave(x);
  }

  static int interleave(int x) {
    x &= 0xffff;
    x = (x ^ (x << 8)) & 0xff00ff;
    x = (x ^ (x << 4)) & 0xf0f0f0f;
    x = (x ^ (x << 2)) & 0x33333333;
    x = (x ^ (x << 1)) & 0x55555555;
    return x;
  }

  static Coordinate decode(int index) {
    int x = deinterleave(index);
    int y = deinterleave(index >> 1);
    return Coordinate(x.toDouble(), y.toDouble());
  }

  static int deinterleave(int x) {
    x = x & 0x55555555;
    x = (x | (x >> 1)) & 0x33333333;
    x = (x | (x >> 2)) & 0xf0f0f0f;
    x = (x | (x >> 4)) & 0xff00ff;
    x = (x | (x >> 8)) & 0xffff;
    return x;
  }
}
