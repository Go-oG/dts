import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'convex_hull.dart';
import 'rectangle.dart';

class MinAreaRectangle {
  static Geometry getMinimumRectangle(Geometry geom) {
    return MinAreaRectangle(geom)._getMinimumRectangle();
  }

  final Geometry _inputGeom;

  final bool _isConvex;

  MinAreaRectangle(this._inputGeom, [this._isConvex = false]);

  Geometry _getMinimumRectangle() {
    if (_inputGeom.isEmpty()) {
      return _inputGeom.factory.createPolygon();
    }
    if (_isConvex) {
      return _computeConvex(_inputGeom);
    }
    Geometry convexGeom = ConvexHull.of(_inputGeom).getConvexHull();
    return _computeConvex(convexGeom);
  }

  Geometry _computeConvex(Geometry convexGeom) {
    List<Coordinate> convexHullPts;
    if (convexGeom is Polygon) {
      convexHullPts = ((convexGeom)).getExteriorRing().getCoordinates();
    } else {
      convexHullPts = convexGeom.getCoordinates();
    }

    if (convexHullPts.isEmpty) {
    } else if (convexHullPts.length == 1) {
      return _inputGeom.factory.createPoint2(convexHullPts[0].copy());
    } else if ((convexHullPts.length == 2) || (convexHullPts.length == 3)) {
      return _computeMaximumLine(convexHullPts, _inputGeom.factory);
    }
    return _computeConvexRing(convexHullPts);
  }

  Polygon _computeConvexRing(List<Coordinate> ring) {
    double minRectangleArea = double.maxFinite;
    int minRectangleBaseIndex = -1;
    int minRectangleDiamIndex = -1;
    int minRectangleLeftIndex = -1;
    int minRectangleRightIndex = -1;
    int diameterIndex = 1;
    int leftSideIndex = 1;
    int rightSideIndex = -1;
    LineSegment segBase = LineSegment.empty();
    LineSegment segDiam = LineSegment.empty();
    for (int i = 0; i < (ring.length - 1); i++) {
      segBase.p0 = ring[i];
      segBase.p1 = ring[i + 1];
      diameterIndex = _findFurthestVertex(ring, segBase, diameterIndex, 0);
      Coordinate diamPt = ring[diameterIndex];
      Coordinate diamBasePt = segBase.project(diamPt);
      segDiam.p0 = diamBasePt;
      segDiam.p1 = diamPt;
      leftSideIndex = _findFurthestVertex(ring, segDiam, leftSideIndex, 1);
      if (i == 0) {
        rightSideIndex = diameterIndex;
      }
      rightSideIndex = _findFurthestVertex(ring, segDiam, rightSideIndex, -1);
      double rectWidth =
          segDiam.distancePerpendicular(ring[leftSideIndex]) + segDiam.distancePerpendicular(ring[rightSideIndex]);
      double rectArea = segDiam.getLength() * rectWidth;
      if (rectArea < minRectangleArea) {
        minRectangleArea = rectArea;
        minRectangleBaseIndex = i;
        minRectangleDiamIndex = diameterIndex;
        minRectangleLeftIndex = leftSideIndex;
        minRectangleRightIndex = rightSideIndex;
      }
    }
    return Rectangle.createFromSidePts(
      ring[minRectangleBaseIndex],
      ring[minRectangleBaseIndex + 1],
      ring[minRectangleDiamIndex],
      ring[minRectangleLeftIndex],
      ring[minRectangleRightIndex],
      _inputGeom.factory,
    );
  }

  int _findFurthestVertex(List<Coordinate> pts, LineSegment baseSeg, int startIndex, int orient) {
    double maxDistance = _orientedDistance(baseSeg, pts[startIndex], orient);
    double nextDistance = maxDistance;
    int maxIndex = startIndex;
    int nextIndex = maxIndex;
    while (_isFurtherOrEqual(nextDistance, maxDistance, orient)) {
      maxDistance = nextDistance;
      maxIndex = nextIndex;
      nextIndex = _nextIndex(pts, maxIndex);
      if (nextIndex == startIndex) {
        break;
      }

      nextDistance = _orientedDistance(baseSeg, pts[nextIndex], orient);
    }
    return maxIndex;
  }

  bool _isFurtherOrEqual(double d1, double d2, int orient) {
    switch (orient) {
      case 0:
        return d1.abs() >= d2.abs();
      case 1:
        return d1 >= d2;
      case -1:
        return d1 <= d2;
    }
    throw ArgumentError("Invalid orientation index: $orient");
  }

  static double _orientedDistance(LineSegment seg, Coordinate p, int orient) {
    double dist = seg.distancePerpendicularOriented(p);
    if (orient == 0) {
      return dist.abs();
    }
    return dist;
  }

  static int _nextIndex(List<Coordinate> ring, int index) {
    index++;
    if (index >= (ring.length - 1)) {
      index = 0;
    }

    return index;
  }

  static LineString _computeMaximumLine(List<Coordinate> pts, GeometryFactory factory) {
    Coordinate? ptMinX;
    Coordinate? ptMaxX;
    Coordinate? ptMinY;
    Coordinate? ptMaxY;
    for (var item in pts) {
      Coordinate p = item;
      if ((ptMinX == null) || (p.x < ptMinX.x)) {
        ptMinX = p;
      }

      if ((ptMaxX == null) || (p.x > ptMaxX.x)) {
        ptMaxX = p;
      }

      if ((ptMinY == null) || (p.y < ptMinY.y)) {
        ptMinY = p;
      }

      if ((ptMaxY == null) || (p.y > ptMaxY.y)) {
        ptMaxY = p;
      }
    }
    Coordinate p0 = ptMinX!;
    Coordinate p1 = ptMaxX!;
    if (p0.x == p1.x) {
      p0 = ptMinY!;
      p1 = ptMaxY!;
    }
    return factory.createLineString2([p0.copy(), p1.copy()]);
  }
}
