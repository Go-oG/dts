import 'dart:ui';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/math/math.dart';
import 'package:dts/src/jts/util/number_util.dart';
import 'package:flutter/foundation.dart';

final class Coordinates {
  Coordinates._();

  static Coordinate create(int dimension) {
    return createWithMeasure(dimension, 0);
  }

  static Coordinate createWithMeasure(int dimension, int measures) {
    if (dimension == 2) {
      return CoordinateXY();
    } else if ((dimension == 3) && (measures == 0)) {
      return Coordinate();
    } else if ((dimension == 3) && (measures == 1)) {
      return CoordinateXYM();
    } else if ((dimension == 4) && (measures == 1)) {
      return CoordinateXYZM();
    }
    return Coordinate();
  }

  static int dimension(Coordinate coordinate) {
    if (coordinate is CoordinateXY) {
      return 2;
    }
    if (coordinate is CoordinateXYM) {
      return 3;
    }
    if (coordinate is CoordinateXYZM) {
      return 4;
    }
    return 3;
  }

  static bool hasZ(Coordinate coordinate) {
    if (coordinate is CoordinateXY) {
      return false;
    }
    if (coordinate is CoordinateXYM) {
      return false;
    }
    if (coordinate is CoordinateXYZM) {
      return true;
    }
    return true;
  }

  static int measures(Coordinate coordinate) {
    if (coordinate is CoordinateXY) {
      return 0;
    }
    if (coordinate is CoordinateXYM) {
      return 1;
    }
    if (coordinate is CoordinateXYZM) {
      return 1;
    }
    return 0;
  }
}

const double _nullOrdinate = double.nan;

class Coordinate implements Comparable<Coordinate> {
  static const int kX = 0;
  static const int kY = 1;
  static const int kZ = 2;
  static const int kM = 3;

  double x;
  double y;

  @protected
  late double mZ;

  double get z => mZ;

  set z(double v) => mZ = v;

  Coordinate([this.x = 0, this.y = 0, double z = _nullOrdinate]) {
    mZ = z;
  }

  Coordinate.of2(Offset c) : this(c.dx, c.dy);

  Coordinate.of(Coordinate c) : this(c.x, c.y, c.z);

  void setCoordinate(Coordinate other) {
    x = other.x;
    y = other.y;
    z = other.z;
  }

  double getM() {
    return double.nan;
  }

  void setM(double m) {
    throw IllegalArgumentException("Invalid ordinate index: $kM");
  }

  double getOrdinate(int ordinateIndex) {
    switch (ordinateIndex) {
      case kX:
        return x;
      case kY:
        return y;
      case kZ:
        return z;
    }
    throw IllegalArgumentException("Invalid ordinate index: $ordinateIndex");
  }

  void setOrdinate(int ordinateIndex, double value) {
    switch (ordinateIndex) {
      case kX:
        x = value;
        break;
      case kY:
        y = value;
        break;
      case kZ:
        z = value;
        break;
      default:
        throw IllegalArgumentException("Invalid ordinate index: $ordinateIndex");
    }
  }

  bool isValid() {
    if (!Double.isFinite(x)) {
      return false;
    }

    if (!Double.isFinite(y)) {
      return false;
    }

    return true;
  }

  bool equals2D(Coordinate other) {
    if (x != other.x) {
      return false;
    }
    if (y != other.y) {
      return false;
    }
    return true;
  }

  bool equals2DWithTolerance(Coordinate c, double tolerance) {
    if (!NumberUtil.equalsWithTolerance(x, c.x, tolerance)) {
      return false;
    }
    if (!NumberUtil.equalsWithTolerance(y, c.y, tolerance)) {
      return false;
    }
    return true;
  }

  bool equals3D(Coordinate other) {
    return (x == other.x && y == other.y) &&
        (z == other.z || (Double.isNaN(z) && Double.isNaN(other.z)));
  }

  bool equalInZ(Coordinate c, double tolerance) {
    return NumberUtil.equalsWithTolerance(z, c.z, tolerance);
  }

  @override
  int compareTo(Coordinate other) {
    if (x < other.x) {
      return -1;
    }

    if (x > other.x) {
      return 1;
    }

    if (y < other.y) {
      return -1;
    }

    if (y > other.y) {
      return 1;
    }
    return 0;
  }

  Coordinate clone() {
    return Coordinate.of(this);
  }

  Coordinate copy() {
    return Coordinate.of(this);
  }

  Coordinate create() {
    return Coordinate();
  }

  double distance(Coordinate c) {
    double dx = x - c.x;
    double dy = y - c.y;
    return MathUtil.hypot(dx, dy);
  }

  double distanceSq(Coordinate c) {
    double dx = x - c.x;
    double dy = y - c.y;
    return (dx * dx) + (dy * dy);
  }

  double distance3D(Coordinate c) {
    double dx = x - c.x;
    double dy = y - c.y;
    double dz = z - c.z;
    return Math.sqrt(((dx * dx) + (dy * dy)) + (dz * dz));
  }

  @override
  int get hashCode {
    int result = 17;
    result = (37 * result) + hashCodeS(x);
    result = (37 * result) + hashCodeS(y);
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Coordinate) {
      return false;
    }
    return equals2D(other);
  }

  static int hashCodeS(double x) {
    int f = Double.doubleToLongBits(x);
    return ((f ^ (f >>> 32)));
  }
}

class CoordinateXY extends Coordinate {
  static const int kX = 0;
  static const int kY = 1;
  static const int kZ = -1;
  static const int kM = -1;

  CoordinateXY([double x = 0, double y = 0]) : super(x, y, _nullOrdinate);

  CoordinateXY.of(Coordinate coord) : super(coord.x, coord.y);

  @override
  CoordinateXY copy() => CoordinateXY.of(this);

  @override
  Coordinate create() => CoordinateXY();

  @override
  set z(double v) {
    throw UnsupportedError("not allow set z");
  }

  @override
  double get z => _nullOrdinate;

  @override
  void setCoordinate(Coordinate other) {
    x = other.x;
    y = other.y;
    z = other.z;
  }

  @override
  double getOrdinate(int ordinateIndex) {
    switch (ordinateIndex) {
      case kX:
        return x;
      case kY:
        return y;
    }
    return double.nan;
  }

  @override
  void setOrdinate(int ordinateIndex, double value) {
    switch (ordinateIndex) {
      case kX:
        x = value;
        break;
      case kY:
        y = value;
        break;
      default:
        throw IllegalArgumentException("Invalid ordinate index: $ordinateIndex");
    }
  }
}

class CoordinateXYM extends Coordinate {
  static const int kX = 0;
  static const int kY = 1;
  static const int kZ = -1;
  static const int kM = 2;
  late double m;

  CoordinateXYM([super.x, super.y, this.m = 0]);

  CoordinateXYM.of(Coordinate coord) : super(coord.x, coord.y) {
    m = getM();
  }

  CoordinateXYM.of2(CoordinateXYM coord) : super(coord.x, coord.y) {
    m = coord.m;
  }

  @override
  CoordinateXYM copy() {
    return CoordinateXYM.of2(this);
  }

  @override
  Coordinate create() {
    return CoordinateXYM();
  }

  @override
  double getM() {
    return m;
  }

  @override
  void setM(double m) {
    this.m = m;
  }

  @override
  double get z => _nullOrdinate;

  @override
  set z(double z) =>
      throw IllegalArgumentException("CoordinateXY dimension 2 does not support z-ordinate");

  @override
  void setCoordinate(Coordinate other) {
    x = other.x;
    y = other.y;
    z = other.z;
    m = other.getM();
  }

  @override
  double getOrdinate(int ordinateIndex) {
    switch (ordinateIndex) {
      case kX:
        return x;
      case kY:
        return y;
      case kM:
        return m;
    }
    throw IllegalArgumentException("Invalid ordinate index: $ordinateIndex");
  }

  @override
  void setOrdinate(int ordinateIndex, double value) {
    switch (ordinateIndex) {
      case kX:
        x = value;
        break;
      case kY:
        y = value;
        break;
      case kM:
        m = value;
        break;
      default:
        throw IllegalArgumentException("Invalid ordinate index: $ordinateIndex");
    }
  }
}

class CoordinateXYZM extends Coordinate {
  late double _m;

  CoordinateXYZM([super.x, super.y, super.z, this._m = 0.0]);

  CoordinateXYZM.of(super.coord) {
    _m = getM();
  }

  CoordinateXYZM.of2(CoordinateXYZM coord) : super.of(coord) {
    _m = coord._m;
  }

  @override
  CoordinateXYZM copy() {
    return CoordinateXYZM.of2(this);
  }

  @override
  Coordinate create() {
    return CoordinateXYZM();
  }

  @override
  double getM() {
    return _m;
  }

  @override
  void setM(double m) {
    _m = m;
  }

  @override
  double getOrdinate(int ordinateIndex) {
    switch (ordinateIndex) {
      case Coordinate.kX:
        return x;
      case Coordinate.kY:
        return y;
      case Coordinate.kZ:
        return z;
      case Coordinate.kM:
        return getM();
    }
    throw IllegalArgumentException("Invalid ordinate index: $ordinateIndex");
  }

  @override
  void setCoordinate(Coordinate other) {
    x = other.x;
    y = other.y;
    z = other.z;
    _m = other.getM();
  }

  @override
  void setOrdinate(int ordinateIndex, double value) {
    switch (ordinateIndex) {
      case Coordinate.kX:
        x = value;
        break;
      case Coordinate.kY:
        y = value;
        break;
      case Coordinate.kZ:
        z = value;
        break;
      case Coordinate.kM:
        _m = value;
        break;
      default:
        throw IllegalArgumentException("Invalid ordinate index: $ordinateIndex");
    }
  }
}

class DimensionalComparator implements CComparator<Coordinate> {
  static int compareS(double a, double b) {
    if (a < b) {
      return -1;
    }

    if (a > b) {
      return 1;
    }

    if (Double.isNaN(a)) {
      if (Double.isNaN(b)) {
        return 0;
      }

      return -1;
    }
    if (Double.isNaN(b)) {
      return 1;
    }

    return 0;
  }

  final int _dimensionsToTest;

  DimensionalComparator([this._dimensionsToTest = 2]) {
    if ((_dimensionsToTest != 2) && (_dimensionsToTest != 3)) {
      throw IllegalArgumentException("only 2 or 3 dimensions may be specified");
    }
  }

  @override
  int compare(Coordinate c1, Coordinate c2) {
    int compX = compareS(c1.x, c2.x);
    if (compX != 0) {
      return compX;
    }

    int compY = compareS(c1.y, c2.y);
    if (compY != 0) {
      return compY;
    }

    if (_dimensionsToTest <= 2) {
      return 0;
    }

    int compZ = compareS(c1.z, c2.z);
    return compZ;
  }
}

abstract interface class CoordinateFilter {
  void filter(Coordinate coord);
}

class CoordinateFilter2 implements CoordinateFilter {
  final void Function(Coordinate coord) apply;

  CoordinateFilter2(this.apply);

  @override
  void filter(Coordinate coord) {
    apply(coord);
  }
}
