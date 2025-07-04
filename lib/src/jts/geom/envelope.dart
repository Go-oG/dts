import 'dart:math';
import 'dart:ui';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/math/math.dart';

import 'coordinate.dart';

final class Envelope implements Comparable<Envelope> {
  static bool intersects3(Coordinate p1, Coordinate p2, Coordinate q) {
    return ((q.x >= Math.min(p1.x, p2.x)) && (q.x <= Math.max(p1.x, p2.x))) &&
        ((q.y >= Math.min(p1.y, p2.y)) && (q.y <= Math.max(p1.y, p2.y)));
  }

  static bool intersects4(Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2) {
    double minq = Math.minD(q1.x, q2.x);
    double maxq = Math.maxD(q1.x, q2.x);
    double minp = Math.minD(p1.x, p2.x);
    double maxp = Math.maxD(p1.x, p2.x);
    if (minp > maxq) return false;

    if (maxp < minq) return false;

    minq = Math.minD(q1.y, q2.y);
    maxq = Math.maxD(q1.y, q2.y);
    minp = Math.minD(p1.y, p2.y);
    maxp = Math.maxD(p1.y, p2.y);
    if (minp > maxq) return false;

    return !(maxp < minq);
  }

  late double _minX;
  late double _maxX;
  late double _minY;
  late double _maxY;

  Envelope() {
    setToNull();
  }

  Envelope.of(Coordinate p1, [Coordinate? p2]) {
    p2 ??= p1;
    initWithLTRB(p1.x, p1.y, p2.x, p2.y);
  }

  Envelope.from(Envelope env) {
    initWithLTRB(env._minX, env._minY, env._maxX, env._maxY);
  }

  Envelope.fromLTRB(double l, double t, double r, double b) {
    initWithLTRB(l, t, r, b);
  }

  Envelope.fromRect(Rect rect) : this.fromLTRB(rect.left, rect.top, rect.right, rect.bottom);

  void initWithLTRB(double l, double t, double r, double b) {
    _minX = min(l, r);
    _minY = min(t, b);

    _maxX = max(l, r);
    _maxY = max(t, b);
  }

  Envelope copy() => Envelope.from(this);

  void setToNull() {
    _minX = 0;
    _maxX = -1;
    _minY = 0;
    _maxY = -1;
  }

  bool get isNull => _maxX < _minX;

  double get width {
    if (isNull) {
      return 0;
    }
    return _maxX - _minX;
  }

  double get height {
    if (isNull) {
      return 0;
    }
    return _maxY - _minY;
  }

  double get diameter {
    if (isNull) {
      return 0;
    }
    return MathUtil.hypot(width, height);
  }

  double get longSide => max(width, height);

  double get shortSide => min(width, height);

  double get minX => _minX;

  double get maxX => _maxX;

  double get minY => _minY;

  double get maxY => _maxY;

  double get area => width * height;

  double get minExtent {
    if (isNull) return 0.0;
    return min(width, height);
  }

  double get maxExtent {
    if (isNull) return 0.0;

    return max(width, height);
  }

  Coordinate get topLeft => Coordinate(minX, minY);

  Coordinate get topRight => Coordinate(maxX, minY);

  Coordinate get bottomLeft => Coordinate(minX, maxY);

  Coordinate get bottomRight => Coordinate(maxX, maxY);

  void expandBy(double deltaX, [double? deltaY]) {
    if (isNull) return;
    deltaY ??= deltaX;
    _minX -= deltaX;
    _maxX += deltaX;
    _minY -= deltaY;
    _maxY += deltaY;
    if ((_minX > _maxX) || (_minY > _maxY)) setToNull();
  }

  void expandToInclude(Envelope other) {
    if (other.isNull) {
      return;
    }
    if (isNull) {
      _minX = other.minX;
      _maxX = other.maxX;
      _minY = other.minY;
      _maxY = other.maxY;
    } else {
      if (other._minX < _minX) {
        _minX = other._minX;
      }
      if (other._maxX > _maxX) {
        _maxX = other._maxX;
      }
      if (other._minY < _minY) {
        _minY = other._minY;
      }
      if (other._maxY > _maxY) {
        _maxY = other._maxY;
      }
    }
  }

  void expandToIncludeCoordinate(Coordinate p) => expandToIncludePoint(p.x, p.y);

  void expandToIncludePoint(double x, double y) {
    if (isNull) {
      _minX = x;
      _maxX = x;
      _minY = y;
      _maxY = y;
    } else {
      if (x < _minX) {
        _minX = x;
      }
      if (x > _maxX) {
        _maxX = x;
      }
      if (y < _minY) {
        _minY = y;
      }
      if (y > _maxY) {
        _maxY = y;
      }
    }
  }

  void translate(double transX, double transY) {
    if (isNull) {
      return;
    }
    initWithLTRB(minX + transX, minY + transY, maxX + transX, maxY + transY);
  }

  Coordinate? centre() {
    if (isNull) return null;

    return Coordinate((minX + maxX) / 2.0, (minY + maxY) / 2.0);
  }

  Envelope intersection(Envelope env) {
    if ((isNull || env.isNull) || (!intersects(env))) return Envelope();

    double intMinX = Math.maxD(_minX, env._minX);
    double intMinY = Math.maxD(_minY, env._minY);
    double intMaxX = Math.minD(_maxX, env._maxX);
    double intMaxY = Math.minD(_maxY, env._maxY);
    return Envelope.fromLTRB(intMinX, intMinY, intMaxX, intMaxY);
  }

  bool intersects(Envelope other) {
    if (isNull || other.isNull) {
      return false;
    }
    return !((((other._minX > _maxX) || (other._maxX < _minX)) || (other._minY > _maxY)) ||
        (other._maxY < _minY));
  }

  bool intersectsCoordinate(Coordinate p) => intersectsPoint(p.x, p.y);

  bool intersectsPoint(double x, double y) {
    if (isNull) return false;
    return !((((x > _maxX) || (x < _minX)) || (y > _maxY)) || (y < _minY));
  }

  bool intersectsCoordinates(Coordinate a, Coordinate b) {
    if (isNull) {
      return false;
    }
    double envMinX = Math.minD(a.x, b.x);
    if (envMinX > _maxX) return false;

    double envMaxX = Math.maxD(a.x, b.x);
    if (envMaxX < _minX) return false;

    double envMinY = Math.minD(a.y, b.y);
    if (envMinY > _maxY) return false;

    double envMaxY = Math.maxD(a.y, b.y);
    if (envMaxY < _minY) return false;

    return true;
  }

  bool disjoint(Envelope other) {
    return !intersects(other);
  }

  bool overlaps(Envelope other) {
    return intersects(other);
  }

  bool overlapsCoordinate(Coordinate p) {
    return intersectsCoordinate(p);
  }

  bool overlapsPoint(double x, double y) => intersectsPoint(x, y);

  bool contains(Envelope other) => covers(other);

  bool containsCoordinate(Coordinate p) => coversCoordinate(p);

  bool containsPoint(double x, double y) => coversPoint(x, y);

  bool containsProperly(Envelope other) {
    if (this == other) return false;
    return covers(other);
  }

  bool coversPoint(double x, double y) {
    if (isNull) return false;

    return (((x >= _minX) && (x <= _maxX)) && (y >= _minY)) && (y <= _maxY);
  }

  bool coversCoordinate(Coordinate p) => coversPoint(p.x, p.y);

  bool covers(Envelope other) {
    if (isNull || other.isNull) {
      return false;
    }
    return (((other.minX >= _minX) && (other.maxX <= _maxX)) && (other.minY >= _minY)) &&
        (other.maxY <= _maxY);
  }

  double distance(Envelope env) {
    if (intersects(env)) return 0;

    double dx = 0.0;
    if (_maxX < env._minX) {
      dx = env._minX - _maxX;
    } else if (_minX > env._maxX) {
      dx = _minX - env._maxX;
    }

    double dy = 0.0;
    if (_maxY < env._minY) {
      dy = env._minY - _maxY;
    } else if (_minY > env._maxY) {
      dy = _minY - env._maxY;
    }

    if (dx == 0.0) return dy;

    if (dy == 0.0) return dx;

    return MathUtil.hypot(dx, dy);
  }

  @override
  int compareTo(Envelope env) {
    if (isNull) {
      if (env.isNull) return 0;

      return -1;
    } else if (env.isNull) {
      return 1;
    }
    if (_minX < env._minX) return -1;

    if (_minX > env._minX) return 1;

    if (_minY < env._minY) return -1;

    if (_minY > env._minY) return 1;

    if (_maxX < env._maxX) return -1;

    if (_maxX > env._maxX) return 1;

    if (_maxY < env._maxY) return -1;

    if (_maxY > env._maxY) return 1;

    return 0;
  }

  @override
  int get hashCode {
    int result = 17;
    result = (37 * result) + Coordinate.hashCodeS(_minX);
    result = (37 * result) + Coordinate.hashCodeS(_maxX);
    result = (37 * result) + Coordinate.hashCodeS(_minY);
    result = (37 * result) + Coordinate.hashCodeS(_maxY);
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Envelope) {
      return false;
    }
    if (isNull) {
      return other.isNull;
    }
    return (((_maxX == other.maxX) && (_maxY == other.maxY)) && (_minX == other.minX)) &&
        (_minY == other.minY);
  }
}
