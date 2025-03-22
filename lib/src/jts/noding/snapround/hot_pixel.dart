 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/cgalgorithms.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

class HotPixel {
  static const double _TOLERANCE = 0.5;

  final Coordinate _originalPt;

  final double _scaleFactor;

  double _hpx = 0;

  double _hpy = 0;

  bool _isNode = false;

  HotPixel(this._originalPt, this._scaleFactor) {
    if (_scaleFactor <= 0) throw ("Scale factor must be non-zero");

    if (_scaleFactor != 1.0) {
      _hpx = scaleRound(_originalPt.getX());
      _hpy = scaleRound(_originalPt.getY());
    } else {
      _hpx = _originalPt.getX();
      _hpy = _originalPt.getY();
    }
  }

  Coordinate getCoordinate() {
    return _originalPt;
  }

  double getScaleFactor() {
    return _scaleFactor;
  }

  double getWidth() {
    return 1.0 / _scaleFactor;
  }

  bool isNode() {
    return _isNode;
  }

  void setToNode() {
    _isNode = true;
  }

  double scaleRound(double val) {
    return Math.round(val * _scaleFactor).toDouble();
  }

  double scale(double val) {
    return val * _scaleFactor;
  }

  bool intersects(Coordinate p) {
    double x = scale(p.x);
    double y = scale(p.y);
    if (x >= (_hpx + _TOLERANCE)) return false;

    if (x < (_hpx - _TOLERANCE)) return false;

    if (y >= (_hpy + _TOLERANCE)) return false;

    if (y < (_hpy - _TOLERANCE)) return false;

    return true;
  }

  bool intersects2(Coordinate p0, Coordinate p1) {
    if (_scaleFactor == 1.0) return intersectsScaled(p0.x, p0.y, p1.x, p1.y);

    double sp0x = scale(p0.x);
    double sp0y = scale(p0.y);
    double sp1x = scale(p1.x);
    double sp1y = scale(p1.y);
    return intersectsScaled(sp0x, sp0y, sp1x, sp1y);
  }

  bool intersectsScaled(double p0x, double p0y, double p1x, double p1y) {
    double px = p0x;
    double py = p0y;
    double qx = p1x;
    double qy = p1y;
    if (px > qx) {
      px = p1x;
      py = p1y;
      qx = p0x;
      qy = p0y;
    }
    double maxx = _hpx + _TOLERANCE;
    double segMinx = Math.minD(px, qx);
    if (segMinx >= maxx) return false;

    double minx = _hpx - _TOLERANCE;
    double segMaxx = Math.maxD(px, qx);
    if (segMaxx < minx) return false;

    double maxy = _hpy + _TOLERANCE;
    double segMiny = Math.minD(py, qy);
    if (segMiny >= maxy) return false;

    double miny = _hpy - _TOLERANCE;
    double segMaxy = Math.maxD(py, qy);
    if (segMaxy < miny) return false;

    if (px == qx) {
      return true;
    }
    if (py == qy) {
      return true;
    }
    int orientUL = CGAlgorithmsDD.orientationIndex2(px, py, qx, qy, minx, maxy);
    if (orientUL == 0) {
      if (py < qy) return false;

      return true;
    }
    int orientUR = CGAlgorithmsDD.orientationIndex2(px, py, qx, qy, maxx, maxy);
    if (orientUR == 0) {
      if (py > qy) return false;

      return true;
    }
    if (orientUL != orientUR) {
      return true;
    }
    int orientLL = CGAlgorithmsDD.orientationIndex2(px, py, qx, qy, minx, miny);
    if (orientLL == 0) {
      return true;
    }
    if (orientLL != orientUL) {
      return true;
    }
    int orientLR = CGAlgorithmsDD.orientationIndex2(px, py, qx, qy, maxx, miny);
    if (orientLR == 0) {
      if (py < qy) return false;

      return true;
    }
    if (orientLL != orientLR) {
      return true;
    }
    if (orientLR != orientUR) {
      return true;
    }
    return false;
  }

  static const int _UPPER_RIGHT = 0;

  static const int _UPPER_LEFT = 1;

  static const int _LOWER_LEFT = 2;

  static const int _LOWER_RIGHT = 3;

  bool intersectsPixelClosure(Coordinate p0, Coordinate p1) {
    double minx = _hpx - _TOLERANCE;
    double maxx = _hpx + _TOLERANCE;
    double miny = _hpy - _TOLERANCE;
    double maxy = _hpy + _TOLERANCE;
    Array<Coordinate> corner = Array(4);
    corner[_UPPER_RIGHT] = Coordinate(maxx, maxy);
    corner[_UPPER_LEFT] = Coordinate(minx, maxy);
    corner[_LOWER_LEFT] = Coordinate(minx, miny);
    corner[_LOWER_RIGHT] = Coordinate(maxx, miny);
    LineIntersector li = RobustLineIntersector();
    li.computeIntersection2(p0, p1, corner[0], corner[1]);
    if (li.hasIntersection()) return true;

    li.computeIntersection2(p0, p1, corner[1], corner[2]);
    if (li.hasIntersection()) return true;

    li.computeIntersection2(p0, p1, corner[2], corner[3]);
    if (li.hasIntersection()) return true;

    li.computeIntersection2(p0, p1, corner[3], corner[0]);
    if (li.hasIntersection()) return true;

    return false;
  }
}
