 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/util/geometry_editor.dart';

class PrecisionReducerCoordinateOperation extends CoordinateOperation {
  PrecisionModel targetPM;

  bool removeCollapsed = true;

  PrecisionReducerCoordinateOperation(this.targetPM, this.removeCollapsed);

  @override
  Array<Coordinate>? edit2(Array<Coordinate> coordinates, Geometry geom) {
    if (coordinates.length == 0) {
      return null;
    }

    Array<Coordinate> reducedCoords = Array(coordinates.length);
    for (int i = 0; i < coordinates.length; i++) {
      Coordinate coord = Coordinate.of(coordinates[i]);
      targetPM.makePrecise(coord);
      reducedCoords[i] = coord;
    }
    CoordinateList noRepeatedCoordList = CoordinateList.of2(reducedCoords, false);
    Array<Coordinate> noRepeatedCoords = noRepeatedCoordList.toCoordinateArray();
    int minLength = 0;
    if (geom is LineString) minLength = 2;

    if (geom is LinearRing) minLength = 4;

    Array<Coordinate>? collapsedCoords = reducedCoords;
    if (removeCollapsed) {
      collapsedCoords = null;
    }

    if (noRepeatedCoords.length < minLength) {
      return collapsedCoords;
    }
    return noRepeatedCoords;
  }
}
