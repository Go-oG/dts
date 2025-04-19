import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/location.dart';

import 'topology_predicate.dart';

abstract class BasicPredicate extends TopologyPredicate {
  static const int _UNKNOWN = -1;

  static const int _FALSE = 0;

  static const int _TRUE = 1;

  static bool isKnown2(int value) {
    return value > _UNKNOWN;
  }

  static bool toBoolean(int value) {
    return value == _TRUE;
  }

  static int toValue(bool val) {
    return val ? _TRUE : _FALSE;
  }

  static bool isIntersection(int locA, int locB) {
    return (locA != Location.exterior) && (locB != Location.exterior);
  }

  int _value = _UNKNOWN;

  @override
  bool isKnown() {
    return isKnown2(_value);
  }

  @override
  bool value() {
    return toBoolean(_value);
  }

  void setValue(int val) {
    if (isKnown()) {
      return;
    }

    _value = val;
  }

  void setValue2(bool val) {
    if (isKnown()) {
      return;
    }

    _value = toValue(val);
  }

  void setValueIf(bool value, bool cond) {
    if (cond) {
      setValue2(value);
    }
  }

  void require(bool cond) {
    if (!cond) {
      setValue2(false);
    }
  }

  void requireCovers2(Envelope a, Envelope b) {
    require(a.covers(b));
  }
}
