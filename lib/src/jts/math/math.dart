import 'dart:math';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/angle.dart';
import 'package:dts/src/jts/algorithm/cgalgorithms.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/util/assert.dart';

class Plane3D {
  static const int kXYPlane = 1;

  static const int kYZPlane = 2;

  static const int kXZPlane = 3;

  final Vector3D _normal;

  final Coordinate _basePt;

  Plane3D(this._normal, this._basePt);

  double orientedDistance(Coordinate p) {
    Vector3D pb = Vector3D.of2(p, _basePt);
    double pbdDotNormal = pb.dot(_normal);
    if (Double.isNaN(pbdDotNormal))
      throw IllegalArgumentException("3D Coordinate has NaN ordinate");

    double d = pbdDotNormal / _normal.length();
    return d;
  }

  int closestAxisPlane() {
    double xmag = Math.abs(_normal.getX());
    double ymag = Math.abs(_normal.getY());
    double zmag = Math.abs(_normal.getZ());
    if (xmag > ymag) {
      if (xmag > zmag) {
        return kYZPlane;
      } else {
        return kXYPlane;
      }
    } else if (zmag > ymag) {
      return kXYPlane;
    }
    return kXZPlane;
  }
}

class Vector3D {
  static double dot2(Coordinate A, Coordinate B, Coordinate C, Coordinate D) {
    double ABx = B.x - A.x;
    double ABy = B.y - A.y;
    double ABz = B.z - A.z;
    double CDx = D.x - C.x;
    double CDy = D.y - C.y;
    double CDz = D.z - C.z;
    return ((ABx * CDx) + (ABy * CDy)) + (ABz * CDz);
  }

  static Vector3D create2(double x, double y, double z) {
    return Vector3D(x, y, z);
  }

  static Vector3D create(Coordinate coord) {
    return Vector3D.of(coord);
  }

  static double dot3(Coordinate v1, Coordinate v2) {
    return ((v1.x * v2.x) + (v1.y * v2.y)) + (v1.z * v2.z);
  }

  late double x;

  late double y;

  late double _z;

  Vector3D.of(Coordinate v) {
    x = v.x;
    y = v.y;
    _z = v.z;
  }

  Vector3D.of2(Coordinate from, Coordinate to) {
    x = to.x - from.x;
    y = to.y - from.y;
    _z = to.z - from.z;
  }

  Vector3D(this.x, this.y, this._z);

  double getX() {
    return x;
  }

  double getY() {
    return y;
  }

  double getZ() {
    return _z;
  }

  Vector3D add(Vector3D v) {
    return create2(x + v.x, y + v.y, _z + v._z);
  }

  Vector3D subtract(Vector3D v) {
    return create2(x - v.x, y - v.y, _z - v._z);
  }

  Vector3D divide(double d) {
    return create2(x / d, y / d, _z / d);
  }

  double dot(Vector3D v) {
    return ((x * v.x) + (y * v.y)) + (_z * v._z);
  }

  double length() {
    return sqrt(((x * x) + (y * y)) + (_z * _z));
  }

  static double length2(Coordinate v) {
    return sqrt(((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
  }

  Vector3D normalize() {
    double lengthV = length();
    if (lengthV > 0.0) return divide(lengthV);

    return create2(0.0, 0.0, 0.0);
  }

  static Coordinate normalize2(Coordinate v) {
    double len = length2(v);
    return Coordinate(v.x / len, v.y / len, v.z / len);
  }

  @override
  int get hashCode {
    int result = 17;
    result = (37 * result) + Coordinate.hashCodeS(x);
    result = (37 * result) + Coordinate.hashCodeS(y);
    result = (37 * result) + Coordinate.hashCodeS(_z);
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Vector3D) {
      return false;
    }
    return ((x == other.x) && (y == other.y)) && (_z == other._z);
  }
}

class Vector2D {
  static Vector2D create2(double x, double y) {
    return Vector2D(x, y);
  }

  static Vector2D create(Vector2D v) {
    return Vector2D.of(v);
  }

  static Vector2D create4(Coordinate coord) {
    return Vector2D.of2(coord);
  }

  static Vector2D create3(Coordinate from, Coordinate to) {
    return Vector2D.of3(from, to);
  }

  late double x;

  late double y;

  Vector2D([this.x = 0, this.y = 0]);

  Vector2D.of(Vector2D v) {
    x = v.x;
    y = v.y;
  }

  Vector2D.of2(Coordinate v) {
    x = v.x;
    y = v.y;
  }

  Vector2D.of3(Coordinate from, Coordinate to) {
    x = to.x - from.x;
    y = to.y - from.y;
  }

  double getX() {
    return x;
  }

  double getY() {
    return y;
  }

  double getComponent(int index) {
    if (index == 0) return x;

    return y;
  }

  Vector2D add(Vector2D v) {
    return create2(x + v.x, y + v.y);
  }

  Vector2D subtract(Vector2D v) {
    return create2(x - v.x, y - v.y);
  }

  Vector2D multiply(double d) {
    return create2(x * d, y * d);
  }

  Vector2D divide(double d) {
    return create2(x / d, y / d);
  }

  Vector2D negate() {
    return create2(-x, -y);
  }

  double length() {
    return MathUtil.hypot(x, y);
  }

  double lengthSquared() {
    return (x * x) + (y * y);
  }

  Vector2D normalize() {
    double lengthV = length();
    if (lengthV > 0.0) {
      return divide(lengthV);
    }

    return create2(0.0, 0.0);
  }

  Vector2D average(Vector2D v) {
    return weightedSum(v, 0.5);
  }

  Vector2D weightedSum(Vector2D v, double frac) {
    return create2((frac * x) + ((1.0 - frac) * v.x), (frac * y) + ((1.0 - frac) * v.y));
  }

  double distance(Vector2D v) {
    double delx = v.x - x;
    double dely = v.y - y;
    return MathUtil.hypot(delx, dely);
  }

  double dot(Vector2D v) {
    return (x * v.x) + (y * v.y);
  }

  double angle() {
    return atan2(y, x);
  }

  double angle2(Vector2D v) {
    return Angle.diff(v.angle(), angle());
  }

  double angleTo(Vector2D v) {
    double a1 = angle();
    double a2 = v.angle();
    double angDel = a2 - a1;
    if (angDel <= (-Math.pi)) return angDel + Angle.piTimes2;

    if (angDel > Math.pi) return angDel - Angle.piTimes2;

    return angDel;
  }

  Vector2D rotate(double angle) {
    double cos = Math.cos(angle);
    double sin = Math.sin(angle);
    return create2((x * cos) - (y * sin), (x * sin) + (y * cos));
  }

  Vector2D? rotateByQuarterCircle(int numQuarters) {
    int nQuad = numQuarters % 4;
    if ((numQuarters < 0) && (nQuad != 0)) {
      nQuad = nQuad + 4;
    }
    switch (nQuad) {
      case 0:
        return create2(x, y);
      case 1:
        return create2(-y, x);
      case 2:
        return create2(-x, -y);
      case 3:
        return create2(y, -x);
    }
    Assert.shouldNeverReachHere();
    return null;
  }

  bool isParallel(Vector2D v) {
    return 0.0 == CGAlgorithmsDD.signOfDet2x22(x, y, v.x, v.y);
  }

  Coordinate translate(Coordinate coord) {
    return Coordinate(x + coord.x, y + coord.y);
  }

  Coordinate toCoordinate() {
    return Coordinate(x, y);
  }

  Vector2D clone() {
    return Vector2D.of(this);
  }

  @override
  int get hashCode {
    int result = 17;
    result = (37 * result) + Coordinate.hashCodeS(x);
    result = (37 * result) + Coordinate.hashCodeS(y);
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Vector2D) {
      return false;
    }
    return (x == other.x) && (y == other.y);
  }
}

final class DD implements Comparable<DD> {
  static final DD kPi = DD(3.141592653589793, 1.2246467991473532E-16);
  static final DD kTwoPi = DD(6.283185307179586, 2.4492935982947064E-16);
  static final DD kPi2 = DD(1.5707963267948966, 6.123233995736766E-17);
  static final DD kE = DD(2.718281828459045, 1.4456468917292502E-16);
  static final DD kNaN = DD(double.nan, double.nan);
  static const double kEPS = 1.23259516440783E-32;
  static const double _kSplit = 1.34217729E8;

  static DD createNaN() {
    return DD(double.nan, double.nan);
  }

  double _hi = 0.0;

  double _lo = 0.0;

  DD(double hi, double lo) {
    init3(hi, lo);
  }

  DD.valueOf([double x = 0.0]) {
    init2(x);
  }

  DD.of(DD dd) {
    init(dd);
  }

  DD clone() {
    return DD.of(this);
  }

  void init2(double x) {
    _hi = x;
    _lo = 0.0;
  }

  void init3(double hi, double lo) {
    _hi = hi;
    _lo = lo;
  }

  void init(DD dd) {
    _hi = dd._hi;
    _lo = dd._lo;
  }

  DD setValue(DD value) {
    init(value);
    return this;
  }

  DD setValue2(double value) {
    init2(value);
    return this;
  }

  DD add(DD y) {
    return clone().selfAdd(y);
  }

  DD add2(double y) {
    return clone().selfAdd2(y);
  }

  DD selfAdd(DD y) {
    return selfAdd3(y._hi, y._lo);
  }

  DD selfAdd2(double y) {
    double H;
    double h;
    double S;
    double s;
    double e;
    double f;
    S = _hi + y;
    e = S - _hi;
    s = S - e;
    s = (y - e) + (_hi - s);
    f = s + _lo;
    H = S + f;
    h = f + (S - H);
    _hi = H + h;
    _lo = h + (H - _hi);
    return this;
  }

  DD selfAdd3(double yhi, double ylo) {
    double H;
    double h;
    double T;
    double t;
    double S;
    double s;
    double e;
    double f;
    S = _hi + yhi;
    T = _lo + ylo;
    e = S - _hi;
    f = T - _lo;
    s = S - e;
    t = T - f;
    s = (yhi - e) + (_hi - s);
    t = (ylo - f) + (_lo - t);
    e = s + T;
    H = S + e;
    h = e + (S - H);
    e = t + h;
    double zhi = H + e;
    double zlo = e + (H - zhi);
    _hi = zhi;
    _lo = zlo;
    return this;
  }

  DD subtract(DD y) {
    return add(y.negate());
  }

  DD subtract2(double y) {
    return add2(-y);
  }

  DD selfSubtract(DD y) {
    if (isNaN()) return this;

    return selfAdd3(-y._hi, -y._lo);
  }

  DD selfSubtract2(double y) {
    if (isNaN()) return this;

    return selfAdd3(-y, 0.0);
  }

  DD negate() {
    if (isNaN()) return this;

    return DD(-_hi, -_lo);
  }

  DD multiply(DD y) {
    if (y.isNaN()) return createNaN();

    return clone().selfMultiply(y);
  }

  DD multiply2(double y) {
    if (Double.isNaN(y)) return createNaN();

    return clone().selfMultiply3(y, 0.0);
  }

  DD selfMultiply(DD y) {
    return selfMultiply3(y._hi, y._lo);
  }

  DD selfMultiply2(double y) {
    return selfMultiply3(y, 0.0);
  }

  DD selfMultiply3(double yhi, double ylo) {
    double hx;
    double tx;
    double hy;
    double ty;
    double C;
    double c;
    C = _kSplit * _hi;
    hx = C - _hi;
    c = _kSplit * yhi;
    hx = C - hx;
    tx = _hi - hx;
    hy = c - yhi;
    C = _hi * yhi;
    hy = c - hy;
    ty = yhi - hy;
    c = (((((hx * hy) - C) + (hx * ty)) + (tx * hy)) + (tx * ty)) + ((_hi * ylo) + (_lo * yhi));
    double zhi = C + c;
    hx = C - zhi;
    double zlo = c + hx;
    _hi = zhi;
    _lo = zlo;
    return this;
  }

  DD divide(DD y) {
    double hc;
    double tc;
    double hy;
    double ty;
    double C;
    double c;
    double U;
    double u;
    C = _hi / y._hi;
    c = _kSplit * C;
    hc = c - C;
    u = _kSplit * y._hi;
    hc = c - hc;
    tc = C - hc;
    hy = u - y._hi;
    U = C * y._hi;
    hy = u - hy;
    ty = y._hi - hy;
    u = ((((hc * hy) - U) + (hc * ty)) + (tc * hy)) + (tc * ty);
    c = ((((_hi - U) - u) + _lo) - (C * y._lo)) / y._hi;
    u = C + c;
    double zhi = u;
    double zlo = (C - u) + c;
    return DD(zhi, zlo);
  }

  DD divide2(double y) {
    if (Double.isNaN(y)) return createNaN();

    return clone().selfDivide3(y, 0.0);
  }

  DD selfDivide(DD y) {
    return selfDivide3(y._hi, y._lo);
  }

  DD selfDivide2(double y) {
    return selfDivide3(y, 0.0);
  }

  DD selfDivide3(double yhi, double ylo) {
    double hc;
    double tc;
    double hy;
    double ty;
    double C;
    double c;
    double U;
    double u;
    C = _hi / yhi;
    c = _kSplit * C;
    hc = c - C;
    u = _kSplit * yhi;
    hc = c - hc;
    tc = C - hc;
    hy = u - yhi;
    U = C * yhi;
    hy = u - hy;
    ty = yhi - hy;
    u = ((((hc * hy) - U) + (hc * ty)) + (tc * hy)) + (tc * ty);
    c = ((((_hi - U) - u) + _lo) - (C * ylo)) / yhi;
    u = C + c;
    _hi = u;
    _lo = (C - u) + c;
    return this;
  }

  DD reciprocal() {
    double hc;
    double tc;
    double hy;
    double ty;
    double C;
    double c;
    double U;
    double u;
    C = 1.0 / _hi;
    c = _kSplit * C;
    hc = c - C;
    u = _kSplit * _hi;
    hc = c - hc;
    tc = C - hc;
    hy = u - _hi;
    U = C * _hi;
    hy = u - hy;
    ty = _hi - hy;
    u = ((((hc * hy) - U) + (hc * ty)) + (tc * hy)) + (tc * ty);
    c = (((1.0 - U) - u) - (C * _lo)) / _hi;
    double zhi = C + c;
    double zlo = (C - zhi) + c;
    return DD(zhi, zlo);
  }

  DD floor() {
    if (isNaN()) return kNaN;

    double fhi = Math.floor(_hi).toDouble();
    double flo = 0.0;
    if (fhi == _hi) {
      flo = _lo.floorToDouble();
    }
    return DD(fhi, flo);
  }

  DD ceil() {
    if (isNaN()) return kNaN;

    double fhi = _hi.ceilToDouble();
    double flo = 0.0;
    if (fhi == _hi) {
      flo = _lo.ceilToDouble();
    }
    return DD(fhi, flo);
  }

  int signum() {
    if (_hi > 0) return 1;

    if (_hi < 0) return -1;

    if (_lo > 0) return 1;

    if (_lo < 0) return -1;

    return 0;
  }

  DD rint() {
    if (isNaN()) return this;

    DD plus5 = add2(0.5);
    return plus5.floor();
  }

  DD trunc() {
    if (isNaN()) return kNaN;

    if (isPositive()) {
      return floor();
    } else {
      return ceil();
    }
  }

  DD abs() {
    if (isNaN()) return kNaN;

    if (isNegative()) return negate();

    return DD.of(this);
  }

  DD sqr() {
    return multiply(this);
  }

  DD selfSqr() {
    return selfMultiply(this);
  }

  static DD sqrS(double x) {
    return DD.valueOf(x).selfMultiply2(x);
  }

  DD sqrt() {
    if (isZero()) return DD.valueOf(0.0);

    if (isNegative()) {
      return kNaN;
    }
    double x = 1.0 / Math.sqrt(_hi);
    double ax = _hi * x;
    DD axdd = DD.valueOf(ax);
    DD diffSq = subtract(axdd.sqr());
    double d2 = diffSq._hi * (x * 0.5);
    return axdd.add2(d2);
  }

  static DD sqrt2(double x) {
    return DD.valueOf(x).sqrt();
  }

  DD pow(int exp) {
    if (exp == 0.0) return DD.valueOf(1.0);

    DD r = DD.of(this);
    DD s = DD.valueOf(1.0);
    int n = exp.abs();
    if (n > 1) {
      while (n > 0) {
        if ((n % 2) == 1) {
          s.selfMultiply(r);
        }
        n ~/= 2;
        if (n > 0) {
          r = r.sqr();
        }
      }
    } else {
      s = r;
    }
    if (exp < 0) {
      return s.reciprocal();
    }

    return s;
  }

  static DD determinant2(double x1, double y1, double x2, double y2) {
    return determinant(DD.valueOf(x1), DD.valueOf(y1), DD.valueOf(x2), DD.valueOf(y2));
  }

  static DD determinant(DD x1, DD y1, DD x2, DD y2) {
    DD det = x1.multiply(y2).selfSubtract(y1.multiply(x2));
    return det;
  }

  DD min(DD x) {
    if (le(x)) {
      return this;
    } else {
      return x;
    }
  }

  DD max(DD x) {
    if (ge(x)) {
      return this;
    } else {
      return x;
    }
  }

  double doubleValue() {
    return _hi + _lo;
  }

  int intValue() {
    return _hi.toInt();
  }

  bool isZero() {
    return (_hi == 0.0) && (_lo == 0.0);
  }

  bool isNegative() {
    return (_hi < 0.0) || ((_hi == 0.0) && (_lo < 0.0));
  }

  bool isPositive() {
    return (_hi > 0.0) || ((_hi == 0.0) && (_lo > 0.0));
  }

  bool isNaN() {
    return Double.isNaN(_hi);
  }

  bool equals(DD y) {
    return (_hi == y._hi) && (_lo == y._lo);
  }

  bool gt(DD y) {
    return (_hi > y._hi) || ((_hi == y._hi) && (_lo > y._lo));
  }

  bool ge(DD y) {
    return (_hi > y._hi) || ((_hi == y._hi) && (_lo >= y._lo));
  }

  bool lt(DD y) {
    return (_hi < y._hi) || ((_hi == y._hi) && (_lo < y._lo));
  }

  bool le(DD y) {
    return (_hi < y._hi) || ((_hi == y._hi) && (_lo <= y._lo));
  }

  @override
  int compareTo(DD other) {
    if (_hi < other._hi) return -1;

    if (_hi > other._hi) return 1;

    if (_lo < other._lo) return -1;

    if (_lo > other._lo) return 1;

    return 0;
  }

  String? getSpecialNumberString() {
    if (isZero()) {
      return "0.0";
    }

    if (isNaN()) {
      return "NaN ";
    }

    return null;
  }

  static int magnitude(double x) {
    double xAbs = Math.abs(x);
    double xLog10 = Math.log(xAbs) / Math.log(10);
    int xMag = Math.floor(xLog10);
    double xApprox = Math.pow(10, xMag.toDouble());
    if ((xApprox * 10) <= xAbs) xMag += 1;

    return xMag;
  }
}

class MathUtil {
  static double clamp2(double x, double min, double max) {
    if (x < min) return min;

    if (x > max) return max;

    return x;
  }

  static int clamp(int x, int min, int max) {
    if (x < min) return min;

    if (x > max) return max;

    return x;
  }

  static int clampMax(int x, int max) {
    if (x > max) return max;

    return x;
  }

  static int ceil(int num, int denom) {
    int div = num ~/ denom;
    return (div * denom) >= num ? div : div + 1;
  }

  static double hypot(double x, double y) {
    return sqrt((x * x) + (y * y));
  }

  static final double _LOG_10 = Math.log(10);

  static double log10(double x) {
    double ln = Math.log(x);
    if (Double.isInfinite(ln)) return ln;

    if (Double.isNaN(ln)) return ln;

    return ln / _LOG_10;
  }

  static int wrap(int index, int max) {
    if (index < 0) {
      return max - ((-index) % max);
    }
    return index % max;
  }

  static double average(double x1, double x2) {
    return (x1 + x2) / 2.0;
  }

  static double max(double v1, double v2, double v3) {
    double max = v1;
    if (v2 > max) max = v2;

    if (v3 > max) max = v3;

    return max;
  }

  static double max2(double v1, double v2, double v3, double v4) {
    double max = v1;
    if (v2 > max) max = v2;

    if (v3 > max) max = v3;

    if (v4 > max) max = v4;

    return max;
  }

  static double min(double v1, double v2, double v3, double v4) {
    double min = v1;
    if (v2 < min) min = v2;

    if (v3 < min) min = v3;

    if (v4 < min) min = v4;

    return min;
  }

  static final double PHI_INV = (sqrt(5) - 1.0) / 2.0;

  static double quasirandom(double curr) {
    return quasirandom2(curr, PHI_INV);
  }

  static double quasirandom2(double curr, double alpha) {
    double next = curr + alpha;
    if (next < 1) return next;

    return next - Math.floor(next);
  }

  static Array<int> shuffle(int n) {
    final Random rnd = Random(13);
    Array<int> ints = Array(n);
    for (int i = 0; i < n; i++) {
      ints[i] = i;
    }
    for (int i = n - 1; i >= 1; i--) {
      int j = rnd.nextInt(i + 1);
      int last = ints[i];
      ints[i] = ints[j];
      ints[j] = last;
    }
    return ints;
  }
}

class Matrix {
  static void swapRows2(Array<Array<double>> m, int i, int j) {
    if (i == j) {
      return;
    }

    for (int col = 0; col < m[0].length; col++) {
      double temp = m[i][col];
      m[i][col] = m[j][col];
      m[j][col] = temp;
    }
  }

  static void swapRows(Array<double> m, int i, int j) {
    if (i == j) {
      return;
    }

    double temp = m[i];
    m[i] = m[j];
    m[j] = temp;
  }

  static Array<double>? solve(Array<Array<double>> a, Array<double> b) {
    int n = b.length;
    if ((a.length != n) || (a[0].length != n)) {
      throw ("Matrix A is incorrectly sized");
    }

    for (int i = 0; i < n; i++) {
      int maxElementRow = i;
      for (int j = i + 1; j < n; j++) {
        if (Math.abs(a[j][i]) > Math.abs(a[maxElementRow][i])) {
          maxElementRow = j;
        }
      }

      if (a[maxElementRow][i] == 0.0) {
        return null;
      }

      swapRows2(a, i, maxElementRow);
      swapRows(b, i, maxElementRow);
      for (int j = i + 1; j < n; j++) {
        double rowFactor = a[j][i] / a[i][i];
        for (int k = n - 1; k >= i; k--) {
          a[j][k] -= a[i][k] * rowFactor;
        }

        b[j] -= b[i] * rowFactor;
      }
    }
    Array<double> solution = Array(n);
    for (int j = n - 1; j >= 0; j--) {
      double t = 0.0;
      for (int k = j + 1; k < n; k++) {
        t += a[j][k] * solution[k];
      }

      solution[j] = (b[j] - t) / a[j][j];
    }
    return solution;
  }
}
