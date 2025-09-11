import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/util/geom_editor.dart';

class PrecisionReducerCoordinateOperation extends CoordinateOperation {
  final PrecisionModel targetPM;

  bool removeCollapsed = true;

  PrecisionReducerCoordinateOperation(this.targetPM, this.removeCollapsed);

  @override
  List<Coordinate>? edit2(List<Coordinate> coordinates, Geometry geom) {
    if (coordinates.isEmpty) {
      return null;
    }

    List<Coordinate> reducedCoords = [];
    for (int i = 0; i < coordinates.length; i++) {
      Coordinate coord = Coordinate.of(coordinates[i]);
      targetPM.makePrecise(coord);
      reducedCoords.add(coord);
    }
    CoordinateList noRepeatedCoordList = CoordinateList(reducedCoords, false);
    final noRepeatedCoords = noRepeatedCoordList.toCoordinateList();
    int minLength = 0;
    if (geom is LineString) minLength = 2;

    if (geom is LinearRing) minLength = 4;

    List<Coordinate>? collapsedCoords = reducedCoords;
    if (removeCollapsed) {
      collapsedCoords = null;
    }

    if (noRepeatedCoords.length < minLength) {
      return collapsedCoords;
    }
    return noRepeatedCoords;
  }
}
