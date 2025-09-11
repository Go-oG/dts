import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

class SplitSegment {
  static Coordinate pointAlongReverse(
      LineSegment seg, double segmentLengthFraction) {
    final coord = Coordinate();
    coord.x = seg.p1.x - (segmentLengthFraction * (seg.p1.x - seg.p0.x));
    coord.y = seg.p1.y - (segmentLengthFraction * (seg.p1.y - seg.p0.y));
    return coord;
  }

  final LineSegment _seg;
  double _segLen = 0;

  late Coordinate _splitPt;
  double _minimumLen = 0.0;

  SplitSegment(this._seg) {
    _segLen = _seg.getLength();
  }

  void setMinimumLength(double minLen) {
    _minimumLen = minLen;
  }

  Coordinate getSplitPoint() {
    return _splitPt;
  }

  void splitAt(double length, Coordinate endPt) {
    double actualLen = getConstrainedLength(length);
    double frac = actualLen / _segLen;
    if (endPt.equals2D(_seg.p0)) {
      _splitPt = _seg.pointAlong(frac);
    } else {
      _splitPt = pointAlongReverse(_seg, frac);
    }
  }

  void splitAt2(Coordinate pt) {
    double minFrac = _minimumLen / _segLen;
    if (pt.distance(_seg.p0) < _minimumLen) {
      _splitPt = _seg.pointAlong(minFrac);
      return;
    }
    if (pt.distance(_seg.p1) < _minimumLen) {
      _splitPt = pointAlongReverse(_seg, minFrac);
      return;
    }
    _splitPt = pt;
  }

  double getConstrainedLength(double len) {
    if (len < _minimumLen) return _minimumLen;
    return len;
  }
}
