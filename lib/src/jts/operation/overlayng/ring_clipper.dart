import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/envelope.dart';

class RingClipper {
  static const int _kBoxLeft = 3;

  static const int _kBoxTop = 2;

  static const int _kBoxRight = 1;

  static const int _kBoxBottom = 0;

  final Envelope _clipEnv;

  double _clipEnvMinY = 0;

  double _clipEnvMaxY = 0;

  double _clipEnvMinX = 0;

  double _clipEnvMaxX = 0;

  RingClipper(this._clipEnv) {
    _clipEnvMinY = _clipEnv.minY;
    _clipEnvMaxY = _clipEnv.maxY;
    _clipEnvMinX = _clipEnv.minX;
    _clipEnvMaxX = _clipEnv.maxX;
  }

  List<Coordinate> clip(List<Coordinate> pts) {
    for (int edgeIndex = 0; edgeIndex < 4; edgeIndex++) {
      bool closeRing = edgeIndex == 3;
      pts = clipToBoxEdge(pts, edgeIndex, closeRing);
      if (pts.isEmpty) {
        return pts;
      }
    }
    return pts;
  }

  List<Coordinate> clipToBoxEdge(
      List<Coordinate> pts, int edgeIndex, bool closeRing) {
    CoordinateList ptsClip = CoordinateList();
    Coordinate p0 = pts[pts.length - 1];
    for (int i = 0; i < pts.length; i++) {
      Coordinate p1 = pts[i];
      if (isInsideEdge(p1, edgeIndex)) {
        if (!isInsideEdge(p0, edgeIndex)) {
          Coordinate intPt = intersection(p0, p1, edgeIndex);
          ptsClip.add3(intPt, false);
        }
        ptsClip.add3(p1.copy(), false);
      } else if (isInsideEdge(p0, edgeIndex)) {
        Coordinate intPt = intersection(p0, p1, edgeIndex);
        ptsClip.add3(intPt, false);
      }
      p0 = p1;
    }
    if (closeRing && (ptsClip.size > 0)) {
      Coordinate start = ptsClip.get(0);
      if (!start.equals2D(ptsClip.get(ptsClip.size - 1))) {
        ptsClip.add(start.copy());
      }
    }
    return ptsClip.toCoordinateList();
  }

  Coordinate intersection(Coordinate a, Coordinate b, int edgeIndex) {
    Coordinate intPt;
    switch (edgeIndex) {
      case _kBoxBottom:
        intPt = Coordinate(intersectionLineY(a, b, _clipEnvMinY), _clipEnvMinY);
        break;
      case _kBoxRight:
        intPt = Coordinate(_clipEnvMaxX, intersectionLineX(a, b, _clipEnvMaxX));
        break;
      case _kBoxTop:
        intPt = Coordinate(intersectionLineY(a, b, _clipEnvMaxY), _clipEnvMaxY);
        break;
      case _kBoxLeft:
      default:
        intPt = Coordinate(_clipEnvMinX, intersectionLineX(a, b, _clipEnvMinX));
    }
    return intPt;
  }

  double intersectionLineY(Coordinate a, Coordinate b, double y) {
    double m = (b.x - a.x) / (b.y - a.y);
    double intercept = (y - a.y) * m;
    return a.x + intercept;
  }

  double intersectionLineX(Coordinate a, Coordinate b, double x) {
    double m = (b.y - a.y) / (b.x - a.x);
    double intercept = (x - a.x) * m;
    return a.y + intercept;
  }

  bool isInsideEdge(Coordinate p, int edgeIndex) {
    bool isInside = false;
    switch (edgeIndex) {
      case _kBoxBottom:
        isInside = p.y > _clipEnvMinY;
        break;
      case _kBoxRight:
        isInside = p.x < _clipEnvMaxX;
        break;
      case _kBoxTop:
        isInside = p.y < _clipEnvMaxY;
        break;
      case _kBoxLeft:
      default:
        isInside = p.x > _clipEnvMinX;
    }
    return isInside;
  }
}
