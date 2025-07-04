import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/area.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/polygonal.dart';
import 'package:dts/src/jts/math/math.dart';

import 'ring_hull.dart';
import 'ring_hull_index.dart';

class PolygonHullSimplifier {
  static Geometry hull(Geometry geom, bool isOuter, double vertexNumFraction) {
    PolygonHullSimplifier hull = PolygonHullSimplifier(geom, isOuter);
    hull.setVertexNumFraction(Math.abs(vertexNumFraction));
    return hull.getResult();
  }

  static Geometry hullByAreaDelta(Geometry geom, bool isOuter, double areaDeltaRatio) {
    PolygonHullSimplifier hull = PolygonHullSimplifier(geom, isOuter);
    hull.setAreaDeltaRatio(Math.abs(areaDeltaRatio));
    return hull.getResult();
  }

  Geometry inputGeom;
  late GeometryFactory geomFactory;
  final bool _isOuter;

  double _vertexNumFraction = -1;

  double _areaDeltaRatio = -1;

  PolygonHullSimplifier(this.inputGeom, this._isOuter) {
    geomFactory = inputGeom.factory;
    if (inputGeom is! Polygonal) {
      throw IllegalArgumentException("Input geometry must be  polygonal");
    }
  }

  void setVertexNumFraction(double vertexNumFraction) {
    double frac = MathUtil.clamp2(vertexNumFraction, 0, 1);
    _vertexNumFraction = frac;
  }

  void setAreaDeltaRatio(double areaDeltaRatio) {
    _areaDeltaRatio = areaDeltaRatio;
  }

  Geometry getResult() {
    final inputGeom = this.inputGeom;
    if ((_vertexNumFraction == 1) || (_areaDeltaRatio == 0)) {
      return inputGeom.copy();
    }

    if (inputGeom is MultiPolygon) {
      bool isOverlapPossible = _isOuter && (inputGeom.getNumGeometries() > 1);
      if (isOverlapPossible) {
        return computeMultiPolygonAll(inputGeom);
      } else {
        return computeMultiPolygonEach(inputGeom);
      }
    } else if (inputGeom is Polygon) {
      return computePolygon(inputGeom);
    }
    throw IllegalArgumentException("Input geometry must be polygonal");
  }

  Geometry computeMultiPolygonAll(MultiPolygon multiPoly) {
    RingHullIndex hullIndex = RingHullIndex();
    int nPoly = multiPoly.getNumGeometries();
    Array<List<RingHull>> polyHulls = Array(nPoly);

    for (int i = 0; i < multiPoly.getNumGeometries(); i++) {
      Polygon poly = multiPoly.getGeometryN(i);
      List<RingHull> ringHulls = initPolygon(poly, hullIndex);
      polyHulls[i] = ringHulls;
    }
    List<Polygon> polys = [];
    for (int i = 0; i < multiPoly.getNumGeometries(); i++) {
      Polygon poly = multiPoly.getGeometryN(i);
      Polygon hull = polygonHull(poly, polyHulls[i], hullIndex);
      polys.add(hull);
    }
    return geomFactory.createMultiPolygon(GeometryFactory.toPolygonArray(polys));
  }

  Geometry computeMultiPolygonEach(MultiPolygon multiPoly) {
    List<Polygon> polys = [];
    for (int i = 0; i < multiPoly.getNumGeometries(); i++) {
      Polygon poly = multiPoly.getGeometryN(i);
      Polygon hull = computePolygon(poly);
      polys.add(hull);
    }
    return geomFactory.createMultiPolygon(GeometryFactory.toPolygonArray(polys));
  }

  Polygon computePolygon(Polygon poly) {
    RingHullIndex? hullIndex;
    bool isOverlapPossible = (!_isOuter) && (poly.getNumInteriorRing() > 0);
    if (isOverlapPossible) {
      hullIndex = RingHullIndex();
    }

    List<RingHull> hulls = initPolygon(poly, hullIndex);
    return polygonHull(poly, hulls, hullIndex);
  }

  List<RingHull> initPolygon(Polygon poly, RingHullIndex? hullIndex) {
    List<RingHull> hulls = [];
    if (poly.isEmpty()) {
      return hulls;
    }

    double areaTotal = 0.0;
    if (_areaDeltaRatio >= 0) {
      areaTotal = ringArea(poly);
    }
    hulls.add(createRingHull(poly.getExteriorRing(), _isOuter, areaTotal, hullIndex));
    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      hulls.add(createRingHull(poly.getInteriorRingN(i), !_isOuter, areaTotal, hullIndex));
    }
    return hulls;
  }

  double ringArea(Polygon poly) {
    double area = Area.ofRing2(poly.getExteriorRing().getCoordinateSequence());
    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      area += Area.ofRing2(poly.getInteriorRingN(i).getCoordinateSequence());
    }
    return area;
  }

  RingHull createRingHull(
      LinearRing ring, bool isOuter, double areaTotal, RingHullIndex? hullIndex) {
    RingHull ringHull = RingHull(ring, isOuter);
    if (_vertexNumFraction >= 0) {
      int targetVertexCount = Math.ceil(_vertexNumFraction * (ring.getNumPoints() - 1));
      ringHull.setMinVertexNum(targetVertexCount);
    } else if (_areaDeltaRatio >= 0) {
      double ringArea = Area.ofRing2(ring.getCoordinateSequence());
      double ringWeight = ringArea / areaTotal;
      double maxAreaDelta = (ringWeight * _areaDeltaRatio) * ringArea;
      ringHull.setMaxAreaDelta(maxAreaDelta);
    }
    if (hullIndex != null) {
      hullIndex.add(ringHull);
    }

    return ringHull;
  }

  Polygon polygonHull(Polygon poly, List<RingHull> ringHulls, RingHullIndex? hullIndex) {
    if (poly.isEmpty()) {
      return geomFactory.createPolygon();
    }

    int ringIndex = 0;
    LinearRing shellHull = ringHulls.get(ringIndex++).getHull(hullIndex);
    List<LinearRing> holeHulls = [];
    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      LinearRing hull = ringHulls.get(ringIndex++).getHull(hullIndex);
      holeHulls.add(hull);
    }
    Array<LinearRing> resultHoles = GeometryFactory.toLinearRingArray(holeHulls);
    return geomFactory.createPolygon(shellHull, resultHoles);
  }
}
