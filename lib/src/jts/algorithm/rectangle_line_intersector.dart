import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';

import 'line_intersector.dart';
import 'robust_line_intersector.dart';

class RectangleLineIntersector {
  final LineIntersector _li = RobustLineIntersector();

  final Envelope _rectEnv;

  late Coordinate _diagUp0;

  late Coordinate _diagUp1;

  late Coordinate _diagDown0;

  late Coordinate _diagDown1;

  RectangleLineIntersector(this._rectEnv) {
    var rectEnv = _rectEnv;
    _diagUp0 = Coordinate(rectEnv.getMinX(), rectEnv.getMinY());
    _diagUp1 = Coordinate(rectEnv.getMaxX(), rectEnv.getMaxY());
    _diagDown0 = Coordinate(rectEnv.getMinX(), rectEnv.getMaxY());
    _diagDown1 = Coordinate(rectEnv.getMaxX(), rectEnv.getMinY());
  }

  bool intersects(Coordinate p0, Coordinate p1) {
    Envelope segEnv = Envelope.of3(p0, p1);
    if (!_rectEnv.intersects6(segEnv)) {
      return false;
    }

    if (_rectEnv.intersects(p0)) {
      return true;
    }

    if (_rectEnv.intersects(p1)) {
      return true;
    }

    if (p0.compareTo(p1) > 0) {
      Coordinate tmp = p0;
      p0 = p1;
      p1 = tmp;
    }
    bool isSegUpwards = false;
    if (p1.y > p0.y) {
      isSegUpwards = true;
    }

    if (isSegUpwards) {
      _li.computeIntersection2(p0, p1, _diagDown0, _diagDown1);
    } else {
      _li.computeIntersection2(p0, p1, _diagUp0, _diagUp1);
    }
    if (_li.hasIntersection()) {
      return true;
    }

    return false;
  }
}
