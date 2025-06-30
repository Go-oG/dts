import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

import 'edge.dart';

class EdgeKey implements Comparable<EdgeKey> {
  static EdgeKey create(OEdge edge) {
    return EdgeKey(edge);
  }

  double _p0x = 0;

  double _p0y = 0;

  double _p1x = 0;

  double _p1y = 0;

  EdgeKey(OEdge edge) {
    initPoints(edge);
  }

  void initPoints(OEdge edge) {
    bool direction = edge.direction();
    if (direction) {
      init(edge.getCoordinate(0), edge.getCoordinate(1));
    } else {
      int len = edge.size();
      init(edge.getCoordinate(len - 1), edge.getCoordinate(len - 2));
    }
  }

  void init(Coordinate p0, Coordinate p1) {
    _p0x = p0.x;
    _p0y = p0.y;
    _p1x = p1.x;
    _p1y = p1.y;
  }

  @override
  int compareTo(EdgeKey ek) {
    if (_p0x < ek._p0x) return -1;

    if (_p0x > ek._p0x) return 1;

    if (_p0y < ek._p0y) return -1;

    if (_p0y > ek._p0y) return 1;

    if (_p1x < ek._p1x) return -1;

    if (_p1x > ek._p1x) return 1;

    if (_p1y < ek._p1y) return -1;

    if (_p1y > ek._p1y) return 1;

    return 0;
  }

  @override
  int get hashCode {
    int result = 17;
    result = (37 * result) + hashCode2(_p0x);
    result = (37 * result) + hashCode2(_p0y);
    result = (37 * result) + hashCode2(_p1x);
    result = (37 * result) + hashCode2(_p1y);
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is! EdgeKey) {
      return false;
    }
    return (((_p0x == other._p0x) && (_p0y == other._p0y)) && (_p1x == other._p1x)) &&
        (_p1y == other._p1y);
  }

  static int hashCode2(double x) {
    int f = Double.doubleToLongBits(x);
    return f ^ (f >>> 32);
  }
}
