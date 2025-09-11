import 'dart:math';

import 'package:d_util/d_util.dart';

import 'coordinate.dart';

class PrecisionModel implements Comparable<PrecisionModel> {
  static PrecisionModel mostPrecise3(PrecisionModel pm1, PrecisionModel pm2) {
    if (pm1.compareTo(pm2) >= 0) return pm1;

    return pm2;
  }

  static const double kMaxPreciseValue = 9.007199254740992E15;

  final PrecisionType type;
  double _scale = 0;
  double _gridSize = 0;

  PrecisionModel([this.type = PrecisionType.floating]) {
    if (type == PrecisionType.fixed) {
      setScale(1.0);
    }
  }

  PrecisionModel.fixed(double scale, [double offsetX = 0, double offsetY = 0])
      : type = PrecisionType.fixed {
    setScale(scale);
  }

  PrecisionModel.from(PrecisionModel pm) : type = pm.type {
    _scale = pm._scale;
    _gridSize = pm._gridSize;
  }

  bool isdoubleing() => type.isFloating || type.isFloatingSingle;

  int getMaxSignificantDigits() {
    int maxSigDigits = 16;
    if (type.isFloating) {
      maxSigDigits = 16;
    } else if (type.isFloatingSingle) {
      maxSigDigits = 6;
    } else if (type.isFixed) {
      maxSigDigits = 1 + (log(getScale()) / log(10)).ceil();
    }
    return maxSigDigits;
  }

  double getScale() => _scale;

  double gridSize() {
    if (isdoubleing()) return double.nan;

    if (_gridSize != 0) return _gridSize;

    return 1.0 / _scale;
  }

  PrecisionType getType() => type;

  void setScale(double scale) {
    if (scale < 0) {
      _gridSize = Math.abs(scale);
      _scale = 1.0 / _gridSize;
    } else {
      _scale = Math.abs(scale);
      _gridSize = 0.0;
    }
  }

  double getOffsetX() => 0;

  double getOffsetY() => 0;

  void toInternal2(Coordinate external, Coordinate internal) {
    if (isdoubleing()) {
      internal.x = external.x;
      internal.y = external.y;
    } else {
      internal.x = makePrecise2(external.x);
      internal.y = makePrecise2(external.y);
    }
    internal.z = external.z;
  }

  Coordinate toInternal(Coordinate external) {
    Coordinate internal = Coordinate.of(external);
    makePrecise(internal);
    return internal;
  }

  Coordinate toExternal(Coordinate internal) {
    Coordinate external = Coordinate.of(internal);
    return external;
  }

  void toExternal2(Coordinate internal, Coordinate external) {
    external.x = internal.x;
    external.y = internal.y;
  }

  void makePrecise(Coordinate coord) {
    if (type.isFloating) return;

    coord.x = makePrecise2(coord.x);
    coord.y = makePrecise2(coord.y);
  }

  double makePrecise2(double val) {
    if (Double.isNaN(val)) return val;

    if (type.isFloatingSingle) {
      return val;
    }
    if (type.isFixed) {
      if (_gridSize > 0) {
        return Math.round(val / _gridSize) * _gridSize;
      } else {
        return Math.round(val * _scale) / _scale;
      }
    }
    return val;
  }

  @override
  int compareTo(PrecisionModel other) {
    int sigDigits = getMaxSignificantDigits();
    int otherSigDigits = other.getMaxSignificantDigits();
    return sigDigits.compareTo(otherSigDigits);
  }

  @override
  int get hashCode {
    final int prime = 31;
    int result = 1;
    result = (prime * result) + type.hashCode;
    int temp;
    temp = Double.doubleToLongBits(_scale);
    result = (prime * result) + ((temp ^ (temp >>> 32)));
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is! PrecisionModel) {
      return false;
    }
    return (type == other.type) && (_scale == other._scale);
  }
}

enum PrecisionType {
  fixed,
  floating,
  floatingSingle;

  bool get isFloating => this == floating;

  bool get isFloatingSingle => this == floatingSingle;

  bool get isFixed => this == fixed;
}
