import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/location.dart';

import 'orientation.dart';

final class RayCrossingCounter {
  static int locatePointInRing(Coordinate p, List<Coordinate> ring) {
    RayCrossingCounter counter = RayCrossingCounter(p);
    for (int i = 1; i < ring.length; i++) {
      Coordinate p1 = ring[i];
      Coordinate p2 = ring[i - 1];
      counter.countSegment(p1, p2);
      if (counter.isOnSegment()) {
        return counter.getLocation();
      }
    }
    return counter.getLocation();
  }

  static int locatePointInRing2(Coordinate p, CoordinateSequence ring) {
    RayCrossingCounter counter = RayCrossingCounter(p);
    Coordinate p1 = Coordinate();
    Coordinate p2 = Coordinate();
    for (int i = 1; i < ring.size(); i++) {
      p1.x = ring.getOrdinate(i, CoordinateSequence.kX);
      p1.y = ring.getOrdinate(i, CoordinateSequence.kY);
      p2.x = ring.getOrdinate(i - 1, CoordinateSequence.kX);
      p2.y = ring.getOrdinate(i - 1, CoordinateSequence.kY);
      counter.countSegment(p1, p2);
      if (counter.isOnSegment()) {
        return counter.getLocation();
      }
    }
    return counter.getLocation();
  }

  final Coordinate _p;

  int _crossingCount = 0;

  bool _isPointOnSegment = false;

  RayCrossingCounter(this._p);

  void countSegment(Coordinate p1, Coordinate p2) {
    if ((p1.x < _p.x) && (p2.x < _p.x)) {
      return;
    }

    if ((_p.x == p2.x) && (_p.y == p2.y)) {
      _isPointOnSegment = true;
      return;
    }
    if ((p1.y == _p.y) && (p2.y == _p.y)) {
      double minx = p1.x;
      double maxx = p2.x;
      if (minx > maxx) {
        minx = p2.x;
        maxx = p1.x;
      }
      if ((_p.x >= minx) && (_p.x <= maxx)) {
        _isPointOnSegment = true;
      }
      return;
    }
    if (((p1.y > _p.y) && (p2.y <= _p.y)) ||
        ((p2.y > _p.y) && (p1.y <= _p.y))) {
      int orient = Orientation.index(p1, p2, _p);
      if (orient == Orientation.collinear) {
        _isPointOnSegment = true;
        return;
      }
      if (p2.y < p1.y) {
        orient = -orient;
      }
      if (orient == Orientation.left) {
        _crossingCount++;
      }
    }
  }

  int getCount() {
    return _crossingCount;
  }

  bool isOnSegment() {
    return _isPointOnSegment;
  }

  int getLocation() {
    if (_isPointOnSegment) {
      return Location.boundary;
    }

    if ((_crossingCount % 2) == 1) {
      return Location.interior;
    }
    return Location.exterior;
  }

  bool isPointInPolygon() {
    return getLocation() != Location.exterior;
  }
}
