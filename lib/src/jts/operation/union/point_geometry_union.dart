import 'dart:collection';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/point_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/puntal.dart';
import 'package:dts/src/jts/geom/util/geometry_combiner.dart';

class PointGeometryUnion {
  static Geometry? union2(Puntal pointGeom, Geometry otherGeom) {
    PointGeometryUnion unioner = PointGeometryUnion(pointGeom, otherGeom);
    return unioner.union();
  }

  late Geometry _pointGeom;

  late Geometry _otherGeom;

  late GeometryFactory geomFact;

  PointGeometryUnion(Puntal pointGeom, Geometry otherGeom) {
    _pointGeom = pointGeom as Geometry;
    _otherGeom = otherGeom;
    geomFact = otherGeom.factory;
  }

  Geometry? union() {
    PointLocator locater = PointLocator.empty();
    Set<Coordinate> exteriorCoords = SplayTreeSet();
    for (int i = 0; i < _pointGeom.getNumGeometries(); i++) {
      Point point = (_pointGeom.getGeometryN(i) as Point);
      Coordinate coord = point.getCoordinate()!;
      int loc = locater.locate(coord, _otherGeom);
      if (loc == Location.exterior) exteriorCoords.add(coord);
    }
    if (exteriorCoords.isEmpty) return _otherGeom;

    Geometry? ptComp;
    Array<Coordinate> coords = CoordinateArrays.toCoordinateArray(exteriorCoords.toList());
    if (coords.length == 1) {
      ptComp = geomFact.createPoint2(coords[0]);
    } else {
      ptComp = geomFact.createMultiPoint5(coords);
    }
    return GeometryCombiner.combine3(ptComp, _otherGeom);
  }
}
