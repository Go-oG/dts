 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'convex_hull.dart';

class MinimumDiameter {
  static Geometry getMinimumRectangleS(Geometry geom) {
    return MinimumDiameter(geom).getMinimumRectangle();
  }

  static Geometry getMinimumDiameter(Geometry geom) {
    return MinimumDiameter(geom).getDiameter();
  }

  late final Geometry inputGeom;

  late final bool isConvex;

  Array<Coordinate>? _convexHullPts;

  LineSegment? _minBaseSeg = LineSegment.empty();

  Coordinate? _minWidthPt;

  int _minPtIndex = 0;

  double _minWidth = 0.0;

  MinimumDiameter(this.inputGeom, [this.isConvex = false]);

  double getLength() {
    _computeMinimumDiameter();
    return _minWidth;
  }

  Coordinate getWidthCoordinate() {
    _computeMinimumDiameter();
    return _minWidthPt!;
  }

  LineString getSupportingSegment() {
    _computeMinimumDiameter();
    return inputGeom.factory.createLineString2([_minBaseSeg!.p0, _minBaseSeg!.p1].toArray());
  }

  LineString getDiameter() {
    _computeMinimumDiameter();

    Coordinate basePt = _minBaseSeg!.project(_minWidthPt!);
    return inputGeom.factory.createLineString2([basePt, _minWidthPt!].toArray());
  }

  void _computeMinimumDiameter() {
    if (_minWidthPt != null) {
      return;
    }
    if (isConvex) {
      _computeWidthConvex(inputGeom);
    } else {
      Geometry convexGeom = ConvexHull.of(inputGeom).getConvexHull();
      _computeWidthConvex(convexGeom);
    }
  }

  void _computeWidthConvex(Geometry convexGeom) {
    if (convexGeom is Polygon) {
      _convexHullPts = ((convexGeom)).getExteriorRing().getCoordinates();
    } else {
      _convexHullPts = convexGeom.getCoordinates();
    }

    if (_convexHullPts!.length == 0) {
      _minWidth = 0.0;
      _minWidthPt = null;
      _minBaseSeg = null;
    } else if (_convexHullPts!.length == 1) {
      _minWidth = 0.0;
      _minWidthPt = _convexHullPts![0];
      _minBaseSeg!.p0 = _convexHullPts![0];
      _minBaseSeg!.p1 = _convexHullPts![0];
    } else if ((_convexHullPts!.length == 2) || (_convexHullPts!.length == 3)) {
      _minWidth = 0.0;
      _minWidthPt = _convexHullPts![0];
      _minBaseSeg!.p0 = _convexHullPts![0];
      _minBaseSeg!.p1 = _convexHullPts![1];
    } else
      _computeConvexRingMinDiameter(_convexHullPts!);
  }

  void _computeConvexRingMinDiameter(Array<Coordinate> pts) {
    _minWidth = double.maxFinite;
    int currMaxIndex = 1;
    LineSegment seg = LineSegment.empty();
    for (int i = 0; i < (pts.length - 1); i++) {
      seg.p0 = pts[i];
      seg.p1 = pts[i + 1];
      currMaxIndex = _findMaxPerpDistance(pts, seg, currMaxIndex);
    }
  }

  int _findMaxPerpDistance(Array<Coordinate> pts, LineSegment seg, int startIndex) {
    double maxPerpDistance = seg.distancePerpendicular(pts[startIndex]);
    double nextPerpDistance = maxPerpDistance;
    int maxIndex = startIndex;
    int nextIndex = maxIndex;
    while (nextPerpDistance >= maxPerpDistance) {
      maxPerpDistance = nextPerpDistance;
      maxIndex = nextIndex;
      nextIndex = _nextIndex(pts, maxIndex);
      if (nextIndex == startIndex) {
        break;
      }

      nextPerpDistance = seg.distancePerpendicular(pts[nextIndex]);
    }
    if (maxPerpDistance < _minWidth) {
      _minPtIndex = maxIndex;
      _minWidth = maxPerpDistance;
      _minWidthPt = pts[_minPtIndex];
      _minBaseSeg = LineSegment.of(seg);
    }
    return maxIndex;
  }

  static int _nextIndex(Array<Coordinate> pts, int index) {
    index++;
    if (index >= pts.length) {
      index = 0;
    }

    return index;
  }

  Geometry getMinimumRectangle() {
    _computeMinimumDiameter();
    if (_minWidth == 0.0) {
      if (_minBaseSeg!.p0.equals2D(_minBaseSeg!.p1)) {
        return inputGeom.factory.createPoint2(_minBaseSeg!.p0.copy());
      }
      return _computeMaximumLine(_convexHullPts!, inputGeom.factory);
    }
    double dx = _minBaseSeg!.p1.x - _minBaseSeg!.p0.x;
    double dy = _minBaseSeg!.p1.y - _minBaseSeg!.p0.y;
    double minPara = double.maxFinite;
    double maxPara = -double.maxFinite;
    double minPerp = double.maxFinite;
    double maxPerp = -double.maxFinite;
    for (int i = 0; i < _convexHullPts!.length; i++) {
      double paraC = _computeC(dx, dy, _convexHullPts![i]);
      if (paraC > maxPara) {
        maxPara = paraC;
      }

      if (paraC < minPara) {
        minPara = paraC;
      }

      double perpC = _computeC(-dy, dx, _convexHullPts![i]);
      if (perpC > maxPerp) {
        maxPerp = perpC;
      }

      if (perpC < minPerp) {
        minPerp = perpC;
      }
    }
    LineSegment maxPerpLine = _computeSegmentForLine(-dx, -dy, maxPerp);
    LineSegment minPerpLine = _computeSegmentForLine(-dx, -dy, minPerp);
    LineSegment maxParaLine = _computeSegmentForLine(-dy, dx, maxPara);
    LineSegment minParaLine = _computeSegmentForLine(-dy, dx, minPara);
    Coordinate p0 = maxParaLine.lineIntersection(maxPerpLine)!;
    Coordinate p1 = minParaLine.lineIntersection(maxPerpLine)!;
    Coordinate p2 = minParaLine.lineIntersection(minPerpLine)!;
    Coordinate p3 = maxParaLine.lineIntersection(minPerpLine)!;
    LinearRing shell = inputGeom.factory.createLinearRing2([p0, p1, p2, p3, p0].toArray());
    return inputGeom.factory.createPolygon(shell);
  }

  static LineString _computeMaximumLine(Array<Coordinate> pts, GeometryFactory factory) {
    Coordinate? ptMinX;
    Coordinate? ptMaxX;
    Coordinate? ptMinY;
    Coordinate? ptMaxY;
    for (var item in pts) {
      Coordinate p = item;
      if ((ptMinX == null) || (p.getX() < ptMinX.getX())) {
        ptMinX = p;
      }

      if ((ptMaxX == null) || (p.getX() > ptMaxX.getX())) {
        ptMaxX = p;
      }

      if ((ptMinY == null) || (p.getY() < ptMinY.getY())) {
        ptMinY = p;
      }

      if ((ptMaxY == null) || (p.getY() > ptMaxY.getY())) {
        ptMaxY = p;
      }
    }
    Coordinate p0 = ptMinX!;
    Coordinate p1 = ptMaxX!;
    if (p0.getX() == p1.getX()) {
      p0 = ptMinY!;
      p1 = ptMaxY!;
    }
    return factory.createLineString2([p0.copy(), p1.copy()].toArray());
  }

  static double _computeC(double a, double b, Coordinate p) {
    return (a * p.y) - (b * p.x);
  }

  static LineSegment _computeSegmentForLine(double a, double b, double c) {
    Coordinate p0;
    Coordinate p1;
    if (Math.abs(b) > Math.abs(a)) {
      p0 = Coordinate(0.0, c / b);
      p1 = Coordinate(1.0, (c / b) - (a / b));
    } else {
      p0 = Coordinate(c / a, 0.0);
      p1 = Coordinate((c / a) - (b / a), 1.0);
    }
    return LineSegment(p0, p1);
  }
}
