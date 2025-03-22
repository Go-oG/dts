 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/math/math.dart';

import 'coordinate.dart';

class Envelope implements Comparable<Envelope> {
  @override
  int get hashCode {
    int result = 17;
    result = (37 * result) + Coordinate.hashCodeS(_minx);
    result = (37 * result) + Coordinate.hashCodeS(_maxx);
    result = (37 * result) + Coordinate.hashCodeS(_miny);
    result = (37 * result) + Coordinate.hashCodeS(_maxy);
    return result;
  }

  @override
  bool operator ==(Object other) {
    return equals(other);
  }

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

  late double _minx;

  late double _maxx;

  late double _miny;

  late double _maxy;

  Envelope() {
    init();
  }

  Envelope.of(Coordinate p) {
    init4(p.x, p.x, p.y, p.y);
  }

  Envelope.of2(Envelope env) {
    init5(env);
  }

  Envelope.of3(Coordinate p1, Coordinate p2) {
    init4(p1.x, p2.x, p1.y, p2.y);
  }

  Envelope.of4(double x1, double x2, double y1, double y2) {
    init4(x1, x2, y1, y2);
  }

  void init() {
    setToNull();
  }

  void init4(double x1, double x2, double y1, double y2) {
    if (x1 < x2) {
      _minx = x1;
      _maxx = x2;
    } else {
      _minx = x2;
      _maxx = x1;
    }
    if (y1 < y2) {
      _miny = y1;
      _maxy = y2;
    } else {
      _miny = y2;
      _maxy = y1;
    }
  }

  Envelope copy() {
    return Envelope.of2(this);
  }

  void init3(Coordinate p1, Coordinate p2) {
    init4(p1.x, p2.x, p1.y, p2.y);
  }

  void init2(Coordinate p) {
    init4(p.x, p.x, p.y, p.y);
  }

  void init5(Envelope env) {
    _minx = env._minx;
    _maxx = env._maxx;
    _miny = env._miny;
    _maxy = env._maxy;
  }

  void setToNull() {
    _minx = 0;
    _maxx = -1;
    _miny = 0;
    _maxy = -1;
  }

  bool isNull() {
    return _maxx < _minx;
  }

  double getWidth() {
    if (isNull()) {
      return 0;
    }
    return _maxx - _minx;
  }

  double getHeight() {
    if (isNull()) {
      return 0;
    }
    return _maxy - _miny;
  }

  double getDiameter() {
    if (isNull()) {
      return 0;
    }
    double w = getWidth();
    double h = getHeight();
    return MathUtil.hypot(w, h);
  }

  double getMinX() {
    return _minx;
  }

  double getMaxX() {
    return _maxx;
  }

  double getMinY() {
    return _miny;
  }

  double getMaxY() {
    return _maxy;
  }

  double getArea() {
    return getWidth() * getHeight();
  }

  double minExtent() {
    if (isNull()) return 0.0;

    double w = getWidth();
    double h = getHeight();
    return Math.minD(w, h);
  }

  double maxExtent() {
    if (isNull()) return 0.0;

    double w = getWidth();
    double h = getHeight();
    return Math.maxD(w, h);
  }

  void expandToInclude(Coordinate p) {
    expandToInclude2(p.x, p.y);
  }

  void expandBy(double distance) {
    expandBy2(distance, distance);
  }

  void expandBy2(double deltaX, double deltaY) {
    if (isNull()) return;

    _minx -= deltaX;
    _maxx += deltaX;
    _miny -= deltaY;
    _maxy += deltaY;
    if ((_minx > _maxx) || (_miny > _maxy)) setToNull();
  }

  void expandToInclude2(double x, double y) {
    if (isNull()) {
      _minx = x;
      _maxx = x;
      _miny = y;
      _maxy = y;
    } else {
      if (x < _minx) {
        _minx = x;
      }
      if (x > _maxx) {
        _maxx = x;
      }
      if (y < _miny) {
        _miny = y;
      }
      if (y > _maxy) {
        _maxy = y;
      }
    }
  }

  void expandToInclude3(Envelope other) {
    if (other.isNull()) {
      return;
    }
    if (isNull()) {
      _minx = other.getMinX();
      _maxx = other.getMaxX();
      _miny = other.getMinY();
      _maxy = other.getMaxY();
    } else {
      if (other._minx < _minx) {
        _minx = other._minx;
      }
      if (other._maxx > _maxx) {
        _maxx = other._maxx;
      }
      if (other._miny < _miny) {
        _miny = other._miny;
      }
      if (other._maxy > _maxy) {
        _maxy = other._maxy;
      }
    }
  }

  void translate(double transX, double transY) {
    if (isNull()) {
      return;
    }
    init4(getMinX() + transX, getMaxX() + transX, getMinY() + transY, getMaxY() + transY);
  }

  Coordinate? centre() {
    if (isNull()) return null;

    return Coordinate((getMinX() + getMaxX()) / 2.0, (getMinY() + getMaxY()) / 2.0);
  }

  Envelope intersection(Envelope env) {
    if ((isNull() || env.isNull()) || (!intersects6(env))) return Envelope();

    double intMinX = Math.maxD(_minx, env._minx);
    double intMinY = Math.maxD(_miny, env._miny);
    double intMaxX = Math.minD(_maxx, env._maxx);
    double intMaxY = Math.minD(_maxy, env._maxy);
    return Envelope.of4(intMinX, intMaxX, intMinY, intMaxY);
  }

  bool intersects6(Envelope other) {
    if (isNull() || other.isNull()) {
      return false;
    }
    return !((((other._minx > _maxx) || (other._maxx < _minx)) || (other._miny > _maxy)) || (other._maxy < _miny));
  }

  bool intersects2(Coordinate a, Coordinate b) {
    if (isNull()) {
      return false;
    }
    double envminx = Math.minD(a.x, b.x);
    if (envminx > _maxx) return false;

    double envmaxx = Math.maxD(a.x, b.x);
    if (envmaxx < _minx) return false;

    double envminy = Math.minD(a.y, b.y);
    if (envminy > _maxy) return false;

    double envmaxy = Math.maxD(a.y, b.y);
    if (envmaxy < _miny) return false;

    return true;
  }

  bool disjoint(Envelope other) {
    return !intersects6(other);
  }

  bool overlaps3(Envelope other) {
    return intersects6(other);
  }

  bool intersects(Coordinate p) {
    return intersects5(p.x, p.y);
  }

  bool overlaps(Coordinate p) {
    return intersects(p);
  }

  bool intersects5(double x, double y) {
    if (isNull()) return false;

    return !((((x > _maxx) || (x < _minx)) || (y > _maxy)) || (y < _miny));
  }

  bool overlaps2(double x, double y) {
    return intersects5(x, y);
  }

  bool contains3(Envelope other) {
    return covers3(other);
  }

  bool contains(Coordinate p) {
    return covers(p);
  }

  bool contains2(double x, double y) {
    return covers2(x, y);
  }

  bool containsProperly(Envelope other) {
    if (equals(other)) return false;

    return covers3(other);
  }

  bool covers2(double x, double y) {
    if (isNull()) return false;

    return (((x >= _minx) && (x <= _maxx)) && (y >= _miny)) && (y <= _maxy);
  }

  bool covers(Coordinate p) {
    return covers2(p.x, p.y);
  }

  bool covers3(Envelope other) {
    if (isNull() || other.isNull()) {
      return false;
    }
    return (((other.getMinX() >= _minx) && (other.getMaxX() <= _maxx)) && (other.getMinY() >= _miny)) &&
        (other.getMaxY() <= _maxy);
  }

  double distance(Envelope env) {
    if (intersects6(env)) return 0;

    double dx = 0.0;
    if (_maxx < env._minx) {
      dx = env._minx - _maxx;
    } else if (_minx > env._maxx) {
      dx = _minx - env._maxx;
    }

    double dy = 0.0;
    if (_maxy < env._miny) {
      dy = env._miny - _maxy;
    } else if (_miny > env._maxy) {
      dy = _miny - env._maxy;
    }

    if (dx == 0.0) return dy;

    if (dy == 0.0) return dx;

    return MathUtil.hypot(dx, dy);
  }

  bool equals(Object other) {
    if (other is! Envelope) {
      return false;
    }
    if (isNull()) {
      return other.isNull();
    }
    return (((_maxx == other.getMaxX()) && (_maxy == other.getMaxY())) && (_minx == other.getMinX())) &&
        (_miny == other.getMinY());
  }

  @override
  int compareTo(Envelope env) {
    if (isNull()) {
      if (env.isNull()) return 0;

      return -1;
    } else if (env.isNull()) {
      return 1;
    }
    if (_minx < env._minx) return -1;

    if (_minx > env._minx) return 1;

    if (_miny < env._miny) return -1;

    if (_miny > env._miny) return 1;

    if (_maxx < env._maxx) return -1;

    if (_maxx > env._maxx) return 1;

    if (_maxy < env._maxy) return -1;

    if (_maxy > env._maxy) return 1;

    return 0;
  }
}
