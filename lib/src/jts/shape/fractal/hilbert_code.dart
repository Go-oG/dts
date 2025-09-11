import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

class HilbertCode {
  static const int kMaxLevel = 16;

  static int size(int level) {
    checkLevel(level);
    return Math.pow(2, 2 * level).toInt();
  }

  static int maxOrdinate(int level) {
    checkLevel(level);
    return Math.pow(2, level).toInt() - 1;
  }

  static int level(int numPoints) {
    int pow2 = (Math.log(numPoints) / Math.log(2)).toInt();
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

  static int encode(int level, int x, int y) {
    int lvl = levelClamp(level);
    x = x << (16 - lvl);
    y = y << (16 - lvl);
    int a = x ^ y;
    int b = 0xffff ^ a;
    int c = 0xffff ^ (x | y);
    int d = x & (y ^ 0xffff);
    int A = a | (b >> 1);
    int B = (a >> 1) ^ a;
    int C = ((c >> 1) ^ (b & (d >> 1))) ^ c;
    int D = ((a & (c >> 1)) ^ (d >> 1)) ^ d;
    a = A;
    b = B;
    c = C;
    d = D;
    A = (a & (a >> 2)) ^ (b & (b >> 2));
    B = (a & (b >> 2)) ^ (b & ((a ^ b) >> 2));
    C ^= (a & (c >> 2)) ^ (b & (d >> 2));
    D ^= (b & (c >> 2)) ^ ((a ^ b) & (d >> 2));
    a = A;
    b = B;
    c = C;
    d = D;
    A = (a & (a >> 4)) ^ (b & (b >> 4));
    B = (a & (b >> 4)) ^ (b & ((a ^ b) >> 4));
    C ^= (a & (c >> 4)) ^ (b & (d >> 4));
    D ^= (b & (c >> 4)) ^ ((a ^ b) & (d >> 4));
    a = A;
    b = B;
    c = C;
    d = D;
    C ^= (a & (c >> 8)) ^ (b & (d >> 8));
    D ^= (b & (c >> 8)) ^ ((a ^ b) & (d >> 8));
    a = C ^ (C >> 1);
    b = D ^ (D >> 1);
    int i0 = x ^ y;
    int i1 = b | (0xffff ^ (i0 | a));
    i0 = (i0 | (i0 << 8)) & 0xff00ff;
    i0 = (i0 | (i0 << 4)) & 0xf0f0f0f;
    i0 = (i0 | (i0 << 2)) & 0x33333333;
    i0 = (i0 | (i0 << 1)) & 0x55555555;
    i1 = (i1 | (i1 << 8)) & 0xff00ff;
    i1 = (i1 | (i1 << 4)) & 0xf0f0f0f;
    i1 = (i1 | (i1 << 2)) & 0x33333333;
    i1 = (i1 | (i1 << 1)) & 0x55555555;
    return ((i1 << 1) | i0) >> (32 - (2 * lvl));
  }

  static int levelClamp(int level) {
    int lvl = (level < 1) ? 1 : level;
    lvl = (lvl > kMaxLevel) ? kMaxLevel : lvl;
    return lvl;
  }

  static Coordinate decode(int level, int index) {
    checkLevel(level);
    int lvl = levelClamp(level);
    index = index << (32 - (2 * lvl));
    int i0 = deinterleave(index);
    int i1 = deinterleave(index >> 1);
    int t0 = (i0 | i1) ^ 0xffff;
    int t1 = i0 & i1;
    int prefixT0 = prefixScan(t0);
    int prefixT1 = prefixScan(t1);
    int a = ((i0 ^ 0xffff) & prefixT1) | (i0 & prefixT0);
    int x = (a ^ i1) >> (16 - lvl);
    int y = ((a ^ i0) ^ i1) >> (16 - lvl);
    return Coordinate(x.toDouble(), y.toDouble());
  }

  static int prefixScan(int x) {
    x = (x >> 8) ^ x;
    x = (x >> 4) ^ x;
    x = (x >> 2) ^ x;
    x = (x >> 1) ^ x;
    return x;
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
