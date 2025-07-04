import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_component_filter.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/precision_model.dart';

import '../overlay/overlay_op.dart';
import 'overlay_util.dart';

final class OverlayPoints {
  static Geometry overlay(
      OverlayOpCode opCode, Geometry geom0, Geometry geom1, PrecisionModel? pm) {
    OverlayPoints overlay = OverlayPoints(opCode, geom0, geom1, pm);
    return overlay.getResult();
  }

  final OverlayOpCode opCode;
  final Geometry _geom0;
  final Geometry _geom1;

  PrecisionModel? pm;

  late GeometryFactory geometryFactory;

  late List<Point> _resultList;

  OverlayPoints(this.opCode, this._geom0, this._geom1, this.pm) {
    geometryFactory = _geom0.factory;
  }

  Geometry getResult() {
    Map<Coordinate, Point> map0 = buildPointMap(_geom0);
    Map<Coordinate, Point> map1 = buildPointMap(_geom1);
    _resultList = [];
    switch (opCode) {
      case OverlayOpCode.intersection:
        computeIntersection(map0, map1, _resultList);
        break;
      case OverlayOpCode.union:
        computeUnion(map0, map1, _resultList);
        break;
      case OverlayOpCode.difference:
        computeDifference(map0, map1, _resultList);
        break;
      case OverlayOpCode.symDifference:
        computeDifference(map0, map1, _resultList);
        computeDifference(map1, map0, _resultList);
        break;
    }
    if (_resultList.isEmpty) {
      return OverlayUtil.createEmptyResult(0, geometryFactory);
    }

    return geometryFactory.buildGeometry(_resultList);
  }

  void computeIntersection(
      Map<Coordinate, Point> map0, Map<Coordinate, Point> map1, List<Point> resultList) {
    for (var entry in map0.entries) {
      if (map1.containsKey(entry.key)) {
        resultList.add(copyPoint(entry.value));
      }
    }
  }

  void computeDifference(
      Map<Coordinate, Point> map0, Map<Coordinate, Point> map1, List<Point> resultList) {
    for (var entry in map0.entries) {
      if (!map1.containsKey(entry.key)) {
        resultList.add(copyPoint(entry.value));
      }
    }
  }

  void computeUnion(
      Map<Coordinate, Point> map0, Map<Coordinate, Point> map1, List<Point> resultList) {
    for (Point p in map0.values) {
      resultList.add(copyPoint(p));
    }
    for (var entry in map1.entries) {
      if (!map0.containsKey(entry.key)) {
        resultList.add(copyPoint(entry.value));
      }
    }
  }

  Point copyPoint(Point pt) {
    if (OverlayUtil.isdoubleing(pm)) {
      return pt.copy();
    }

    CoordinateSequence seq = pt.getCoordinateSequence();
    CoordinateSequence seq2 = seq.copy();
    seq2.setOrdinate(0, CoordinateSequence.kX, pm!.makePrecise2(seq.getX(0)));
    seq2.setOrdinate(0, CoordinateSequence.kY, pm!.makePrecise2(seq.getY(0)));
    return geometryFactory.createPoint3(seq2);
  }

  Map<Coordinate, Point> buildPointMap(Geometry geoms) {
    Map<Coordinate, Point> map = {};
    geoms.apply4(
      GeomComponentFilter2((geom) {
        if (geom is! Point) {
          return;
        }

        if (geom.isEmpty()) {
          return;
        }

        Coordinate p = roundCoord(geom, pm!);
        if (!map.containsKey(p)) {
          map[p] = geom;
        }
      }),
    );
    return map;
  }

  static Coordinate roundCoord(Point pt, PrecisionModel pm) {
    Coordinate p = pt.getCoordinate()!;
    if (OverlayUtil.isdoubleing(pm)) {
      return p;
    }

    Coordinate p2 = p.copy();
    pm.makePrecise(p2);
    return p2;
  }
}
