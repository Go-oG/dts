import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/geometry_filter.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';
import 'package:dts/src/jts/geom/multi_point.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/util/component_coordinate_extracter.dart';

import 'dimension_location.dart';
import 'relate_point_locator.dart';
import 'relate_segment_string.dart';

class RelateGeometry {
  static const bool kGeomA = true;
  static const bool kGeomB = false;

  static String name(bool isA) {
    return isA ? "A" : "B";
  }

  Geometry geom;

  bool _isPrepared = false;

  late Envelope _geomEnv;

  int _geomDim = Dimension.kFalse;

  Set<Coordinate>? _uniquePoints;

  late BoundaryNodeRule boundaryNodeRule;

  RelatePointLocator? _locator;

  int _elementId = 0;

  bool _hasPoints = false;

  bool _hasLines = false;

  bool _hasAreas = false;

  bool _isLineZeroLen = false;

  bool _isGeomEmpty = false;

  RelateGeometry(this.geom, [this._isPrepared = false, BoundaryNodeRule? bnRule]) {
    _geomEnv = geom.getEnvelopeInternal();
    boundaryNodeRule = bnRule ?? BoundaryNodeRule.ogcSfsBR;
    _isGeomEmpty = geom.isEmpty();
    _geomDim = geom.getDimension();
    analyzeDimensions();
    _isLineZeroLen = isZeroLengthLine(geom);
  }
  RelateGeometry.of(Geometry geom, [BoundaryNodeRule? bnRule]) : this(geom, false, bnRule);

  bool isZeroLengthLine(Geometry geom) {
    if (getDimension() != Dimension.L) {
      return false;
    }

    return isZeroLength(geom);
  }

  void analyzeDimensions() {
    if (_isGeomEmpty) {
      return;
    }
    if ((geom is Point) || (geom is MultiPoint)) {
      _hasPoints = true;
      _geomDim = Dimension.P;
      return;
    }
    if ((geom is LineString) || (geom is MultiLineString)) {
      _hasLines = true;
      _geomDim = Dimension.L;
      return;
    }
    if ((geom is Polygon) || (geom is MultiPolygon)) {
      _hasAreas = true;
      _geomDim = Dimension.A;
      return;
    }
    final geomi = GeometryCollectionIterator(geom);
    while (geomi.moveNext()) {
      Geometry elem = geomi.current;
      if (elem.isEmpty()) {
        continue;
      }

      if (elem is Point) {
        _hasPoints = true;
        if (_geomDim < Dimension.P) {
          _geomDim = Dimension.P;
        }
      }
      if (elem is LineString) {
        _hasLines = true;
        if (_geomDim < Dimension.L) {
          _geomDim = Dimension.L;
        }
      }
      if (elem is Polygon) {
        _hasAreas = true;
        if (_geomDim < Dimension.A) {
          _geomDim = Dimension.A;
        }
      }
    }
  }

  static bool isZeroLength(Geometry geom) {
    final geomi = GeometryCollectionIterator(geom);
    while (geomi.moveNext()) {
      Geometry elem = geomi.current;
      if (elem is LineString) {
        if (!isZeroLength2(elem)) {
          return false;
        }
      }
    }
    return true;
  }

  static bool isZeroLength2(LineString line) {
    if (line.getNumPoints() >= 2) {
      Coordinate p0 = line.getCoordinateN(0);
      for (int i = 0; i < line.getNumPoints(); i++) {
        Coordinate pi = line.getCoordinateN(i);
        if (!p0.equals2D(pi)) {
          return false;
        }
      }
    }
    return true;
  }

  Geometry getGeometry() {
    return geom;
  }

  bool isPrepared() {
    return _isPrepared;
  }

  Envelope getEnvelope() {
    return _geomEnv;
  }

  int getDimension() {
    return _geomDim;
  }

  bool hasDimension(int dim) {
    switch (dim) {
      case Dimension.P:
        return _hasPoints;
      case Dimension.L:
        return _hasLines;
      case Dimension.A:
        return _hasAreas;
    }
    return false;
  }

  bool hasAreaAndLine() {
    return _hasAreas && _hasLines;
  }

  int getDimensionReal() {
    if (_isGeomEmpty) {
      return Dimension.kFalse;
    }

    if ((getDimension() == 1) && _isLineZeroLen) {
      return Dimension.P;
    }

    if (_hasAreas) {
      return Dimension.A;
    }

    if (_hasLines) {
      return Dimension.L;
    }

    return Dimension.P;
  }

  bool hasEdges() {
    return _hasLines || _hasAreas;
  }

  RelatePointLocator getLocator() {
    _locator ??= RelatePointLocator(geom, _isPrepared, boundaryNodeRule);
    return _locator!;
  }

  bool isNodeInArea(Coordinate nodePt, Geometry? parentPolygonal) {
    int loc = getLocator().locateNodeWithDim(nodePt, parentPolygonal);
    return loc == DimensionLocation.kAreaInterior;
  }

  int locateLineEndWithDim(Coordinate p) {
    return getLocator().locateLineEndWithDim(p);
  }

  int locateAreaVertex(Coordinate pt) {
    return locateNode(pt, null);
  }

  int locateNode(Coordinate pt, Geometry? parentPolygonal) {
    return getLocator().locateNode(pt, parentPolygonal);
  }

  int locateWithDim(Coordinate pt) {
    int loc = getLocator().locateWithDim(pt);
    return loc;
  }

  bool isSelfNodingRequired() {
    if ((((geom is Point) || (geom is MultiPoint)) || (geom is Polygon)) || (geom is MultiPolygon)) {
      return false;
    }

    if (_hasAreas && (geom.getNumGeometries() == 1)) {
      return false;
    }

    if ((!_hasAreas) && (!_hasLines)) {
      return false;
    }

    return true;
  }

  bool isPolygonal() {
    return (geom is Polygon) || (geom is MultiPolygon);
  }

  bool isEmpty() {
    return _isGeomEmpty;
  }

  bool hasBoundary() {
    return getLocator().hasBoundary();
  }

  Set<Coordinate> getUniquePoints() {
    _uniquePoints ??= createUniquePoints();
    return _uniquePoints!;
  }

  Set<Coordinate> createUniquePoints() {
    List<Coordinate> pts = ComponentCoordinateExtracter.getCoordinates(geom);
    Set<Coordinate> set = <Coordinate>{};
    set.addAll(pts);
    return set;
  }

  List<Point> getEffectivePoints() {
    List<Point> ptListAll = PointExtracter.getPoints(geom);
    if (getDimensionReal() <= Dimension.P) {
      return ptListAll;
    }

    List<Point> ptList = [];
    for (Point p in ptListAll) {
      if (p.isEmpty()) {
        continue;
      }

      int locDim = locateWithDim(p.getCoordinate()!);
      if (DimensionLocation.dimension(locDim) == Dimension.P) {
        ptList.add(p);
      }
    }
    return ptList;
  }

  List<RelateSegmentString> extractSegmentStrings(bool isA, Envelope? env) {
    List<RelateSegmentString> segStrings = [];
    extractSegmentStrings2(isA, env, geom, segStrings);
    return segStrings;
  }

  void extractSegmentStrings2(bool isA, Envelope? env, Geometry geom, List<RelateSegmentString> segStrings) {
    MultiPolygon? parentPolygonal;
    if (geom is MultiPolygon) {
      parentPolygonal = geom;
    }
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry g = geom.getGeometryN(i);
      if (g is GeometryCollection) {
        extractSegmentStrings2(isA, env, g, segStrings);
      } else {
        extractSegmentStringsFromAtomic(isA, g, parentPolygonal, env, segStrings);
      }
    }
  }

  void extractSegmentStringsFromAtomic(
    bool isA,
    Geometry geom,
    MultiPolygon? parentPolygonal,
    Envelope? env,
    List<RelateSegmentString> segStrings,
  ) {
    if (geom.isEmpty()) {
      return;
    }

    bool doExtract = (env == null) || env.intersects(geom.getEnvelopeInternal());
    if (!doExtract) {
      return;
    }
    _elementId++;
    if (geom is LineString) {
      RelateSegmentString ss = RelateSegmentString.createLine(geom.getCoordinates(), isA, _elementId, this);
      segStrings.add(ss);
    } else if (geom is Polygon) {
      Polygon poly = geom;
      Geometry parentPoly = (parentPolygonal != null) ? parentPolygonal : poly;
      extractRingToSegmentString(isA, poly.getExteriorRing(), 0, env, parentPoly, segStrings);
      for (int i = 0; i < poly.getNumInteriorRing(); i++) {
        extractRingToSegmentString(isA, poly.getInteriorRingN(i), i + 1, env, parentPoly, segStrings);
      }
    }
  }

  void extractRingToSegmentString(
    bool isA,
    LinearRing ring,
    int ringId,
    Envelope? env,
    Geometry parentPoly,
    List<RelateSegmentString> segStrings,
  ) {
    if (ring.isEmpty()) {
      return;
    }

    if ((env != null) && (!env.intersects(ring.getEnvelopeInternal()))) {
      return;
    }

    bool requireCW = ringId == 0;
    final pts = orient(ring.getCoordinates(), requireCW);
    final ss = RelateSegmentString.createRing(pts, isA, _elementId, ringId, parentPoly, this);
    segStrings.add(ss);
  }

  static List<Coordinate> orient(List<Coordinate> pts, bool orientCW) {
    bool isFlipped = orientCW == Orientation.isCCW(pts);
    if (isFlipped) {
      pts = pts.copy();
      CoordinateArrays.reverse(pts);
    }
    return pts;
  }

  @override
  String toString() {
    return geom.toString();
  }
}
