import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/precision_model.dart';

import '../overlay/overlay_op.dart';
import 'indexed_point_on_line_locator.dart';
import 'overlay_ng.dart';
import 'overlay_util.dart';

class OverlayMixedPoints {
  static Geometry overlay(
      OverlayOpCode opCode, Geometry geom0, Geometry geom1, PrecisionModel? pm) {
    return OverlayMixedPoints(opCode, geom0, geom1, pm).getResult();
  }

  final OverlayOpCode _opCode;

  final PrecisionModel? pm;

  late final Geometry _geomPoint;

  late final Geometry _geomNonPointInput;

  late final GeomFactory geometryFactory;

  late final bool _isPointRHS;

  late Geometry _geomNonPoint;

  late int _geomNonPointDim;

  late PointOnGeometryLocator _locator;

  late int _resultDim;

  OverlayMixedPoints(this._opCode, Geometry geom0, Geometry geom1, this.pm) {
    geometryFactory = geom0.factory;
    _resultDim = OverlayUtil.resultDimension(_opCode, geom0.getDimension(), geom1.getDimension());
    if (geom0.getDimension() == 0) {
      _geomPoint = geom0;
      _geomNonPointInput = geom1;
      _isPointRHS = false;
    } else {
      _geomPoint = geom1;
      _geomNonPointInput = geom0;
      _isPointRHS = true;
    }
  }

  Geometry getResult() {
    _geomNonPoint = prepareNonPoint(_geomNonPointInput);
    _geomNonPointDim = _geomNonPoint.getDimension();
    _locator = createLocator(_geomNonPoint);
    Array<Coordinate> coords = extractCoordinates(_geomPoint, pm);
    switch (_opCode) {
      case OverlayOpCode.intersection:
        return computeIntersection(coords);
      case OverlayOpCode.union:
      case OverlayOpCode.symDifference:
        return computeUnion(coords);
      case OverlayOpCode.difference:
        return computeDifference(coords);
    }
  }

  PointOnGeometryLocator createLocator(Geometry geomNonPoint) {
    if (_geomNonPointDim == 2) {
      return IndexedPointInAreaLocator(geomNonPoint);
    } else {
      return IndexedPointOnLineLocator(geomNonPoint);
    }
  }

  Geometry prepareNonPoint(Geometry geomInput) {
    if (_resultDim == 0) {
      return geomInput;
    }
    Geometry geomPrep = OverlayNG.union(_geomNonPointInput, pm);
    return geomPrep;
  }

  Geometry computeIntersection(Array<Coordinate> coords) {
    return createPointResult(findPoints(true, coords));
  }

  Geometry computeUnion(Array<Coordinate> coords) {
    List<Point> resultPointList = findPoints(false, coords);
    List<LineString>? resultLineList;
    if (_geomNonPointDim == 1) {
      resultLineList = extractLines(_geomNonPoint);
    }
    List<Polygon>? resultPolyList;
    if (_geomNonPointDim == 2) {
      resultPolyList = extractPolygons(_geomNonPoint);
    }
    return OverlayUtil.createResultGeometry(
        resultPolyList, resultLineList, resultPointList, geometryFactory);
  }

  Geometry computeDifference(Array<Coordinate> coords) {
    if (_isPointRHS) {
      return copyNonPoint();
    }
    return createPointResult(findPoints(false, coords));
  }

  Geometry createPointResult(List<Point> points) {
    if (points.size == 0) {
      return geometryFactory.createEmpty(0);
    } else if (points.size == 1) {
      return points.get(0);
    }
    Array<Point> pointsArray = GeomFactory.toPointArray(points);
    return geometryFactory.createMultiPoint(pointsArray);
  }

  List<Point> findPoints(bool isCovered, Array<Coordinate> coords) {
    Set<Coordinate> resultCoords = <Coordinate>{};
    for (Coordinate coord in coords) {
      if (hasLocation(isCovered, coord)) {
        resultCoords.add(coord.copy());
      }
    }
    return createPoints(resultCoords);
  }

  List<Point> createPoints(Set<Coordinate> coords) {
    List<Point> points = [];
    for (Coordinate coord in coords) {
      Point point = geometryFactory.createPoint2(coord);
      points.add(point);
    }
    return points;
  }

  bool hasLocation(bool isCovered, Coordinate coord) {
    bool isExterior = Location.exterior == _locator.locate(coord);
    if (isCovered) {
      return !isExterior;
    }
    return isExterior;
  }

  Geometry copyNonPoint() {
    if (_geomNonPointInput != _geomNonPoint) return _geomNonPoint;

    return _geomNonPoint.copy();
  }

  static Array<Coordinate> extractCoordinates(Geometry points, PrecisionModel? pm) {
    CoordinateList coords = CoordinateList();
    points.apply(
      CoordinateFilter2((coord) {
        Coordinate p = OverlayUtil.round(coord, pm);
        coords.add3(p, false);
      }),
    );

    return coords.toCoordinateArray();
  }

  static List<Polygon> extractPolygons(Geometry geom) {
    List<Polygon> list = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Polygon poly = (geom.getGeometryN(i) as Polygon);
      if (!poly.isEmpty()) {
        list.add(poly);
      }
    }
    return list;
  }

  static List<LineString> extractLines(Geometry geom) {
    List<LineString> list = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      LineString line = geom.getGeometryN(i) as LineString;
      if (!line.isEmpty()) {
        list.add(line);
      }
    }
    return list;
  }
}
