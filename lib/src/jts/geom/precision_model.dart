import 'package:d_util/d_util.dart';

import 'coordinate.dart';

class PrecisionModel implements Comparable<PrecisionModel> {
  static PrecisionModel mostPrecise3(PrecisionModel pm1, PrecisionModel pm2) {
    if (pm1.compareTo(pm2) >= 0) return pm1;

    return pm2;
  }

  static final Type FIXED = Type("FIXED");
  static final Type FLOATING = Type("FLOATING");
  static final Type FLOATING_SINGLE = Type("FLOATING SINGLE");
  static const double maximumPreciseValue = 9.007199254740992E15;

  late Type _modelType;

  late double _scale;

  late double _gridSize;

  PrecisionModel([Type? modelType]) {
    _modelType = modelType ?? FLOATING;
    if (_modelType == FIXED) {
      setScale(1.0);
    }
  }

  PrecisionModel.fixed(double scale) {
    _modelType = FIXED;
    setScale(scale);
  }

  PrecisionModel.fixed2(double scale, double offsetX, double offsetY) {
    _modelType = FIXED;
    setScale(scale);
  }

  PrecisionModel.of(PrecisionModel pm) {
    _modelType = pm._modelType;
    _scale = pm._scale;
    _gridSize = pm._gridSize;
  }

  bool isdoubleing() {
    return (_modelType == FLOATING) || (_modelType == FLOATING_SINGLE);
  }

  int getMaximumSignificantDigits() {
    int maxSigDigits = 16;
    if (_modelType == FLOATING) {
      maxSigDigits = 16;
    } else if (_modelType == FLOATING_SINGLE) {
      maxSigDigits = 6;
    } else if (_modelType == FIXED) {
      maxSigDigits = 1 + ((Math.ceil(Math.log(getScale()) / Math.log(10))));
    }
    return maxSigDigits;
  }

  double getScale() {
    return _scale;
  }

  double gridSize() {
    if (isdoubleing()) return double.nan;

    if (_gridSize != 0) return _gridSize;

    return 1.0 / _scale;
  }

  Type getType() {
    return _modelType;
  }

  void setScale(double scale) {
    if (scale < 0) {
      _gridSize = Math.abs(scale);
      _scale = 1.0 / _gridSize;
    } else {
      _scale = Math.abs(scale);
      _gridSize = 0.0;
    }
  }

  double getOffsetX() {
    return 0;
  }

  double getOffsetY() {
    return 0;
  }

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

  double makePrecise2(double val) {
    if (Double.isNaN(val)) return val;

    if (_modelType == FLOATING_SINGLE) {
      double floatSingleVal = (val);
      return floatSingleVal;
    }
    if (_modelType == FIXED) {
      if (_gridSize > 0) {
        return Math.round(val / _gridSize) * _gridSize;
      } else {
        return Math.round(val * _scale) / _scale;
      }
    }
    return val;
  }

  void makePrecise(Coordinate coord) {
    if (_modelType == FLOATING) return;

    coord.x = makePrecise2(coord.x);
    coord.y = makePrecise2(coord.y);
  }

  @override
  String toString() {
    String description = "UNKNOWN";
    if (_modelType == FLOATING) {
      description = "doubleing";
    } else if (_modelType == FLOATING_SINGLE) {
      description = "doubleing-Single";
    } else if (_modelType == FIXED) {
      description = "Fixed (Scale=${getScale()})";
    }
    return description;
  }

  @override
  int compareTo(PrecisionModel other) {
    int sigDigits = getMaximumSignificantDigits();
    int otherSigDigits = other.getMaximumSignificantDigits();
    return sigDigits.compareTo(otherSigDigits);
  }

  @override
  int get hashCode {
    final int prime = 31;
    int result = 1;
    result = (prime * result) + _modelType.hashCode;
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
    return (_modelType == other._modelType) && (_scale == other._scale);
  }
}

class Type {
  static final Map<String, Type> _nameToTypeMap = {};
  final String _name;

  Type(this._name) {
    _nameToTypeMap.put(_name, this);
  }

  @override
  String toString() {
    return _name;
  }

  Type? readResolve() {
    return _nameToTypeMap.get(_name);
  }
}
