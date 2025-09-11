import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/util/geometry_transformer.dart';
import 'package:dts/src/jts/operation/overlayng/precision_reducer.dart';

import '../geom/line_string.dart';

class PrecisionReducerTransformer extends GeometryTransformer {
  static Geometry? reduce(Geometry geom, PrecisionModel targetPM, bool isRemoveCollapsed) {
    PrecisionReducerTransformer trans = PrecisionReducerTransformer(targetPM, isRemoveCollapsed);
    return trans.transform(geom);
  }

  final PrecisionModel targetPM;

  final bool _isRemoveCollapsed;

  PrecisionReducerTransformer(this.targetPM, this._isRemoveCollapsed);

  @override
  CoordinateSequence? transformCoordinates(CoordinateSequence coords, Geometry? parent) {
    if (coords.size() == 0) {
      return null;
    }

    List<Coordinate> coordsReduce = reduceCompress(coords);
    int minSize = 0;
    if (parent is LineString) {
      minSize = 2;
    }

    if (parent is LinearRing) {
      minSize = LinearRing.kMinValidSize;
    }

    if (coordsReduce.length < minSize) {
      if (_isRemoveCollapsed) {
        return null;
      }
      coordsReduce = extend(coordsReduce, minSize);
    }
    return factory.csFactory.create(coordsReduce);
  }

  List<Coordinate> extend(List<Coordinate> coords, int minLength) {
    if (coords.length >= minLength) {
      return coords;
    }

    List<Coordinate> exCoords = [];
    for (int i = 0; i < exCoords.length; i++) {
      int iSrc = (i < coords.length) ? i : coords.length - 1;
      exCoords.add(coords[iSrc].copy());
    }
    return exCoords.toList();
  }

  List<Coordinate> reduceCompress(CoordinateSequence coordinates) {
    CoordinateList noRepeatCoordList = CoordinateList();
    for (int i = 0; i < coordinates.size(); i++) {
      Coordinate coord = coordinates.getCoordinate(i).copy();
      targetPM.makePrecise(coord);
      noRepeatCoordList.add3(coord, false);
    }
    return noRepeatCoordList.toCoordinateList();
  }

  @override
  Geometry transformPolygon(Polygon geom, Geometry? parent) {
    return reduceArea(geom);
  }

  @override
  Geometry transformMultiPolygon(MultiPolygon geom, Geometry? parent) {
    return reduceArea(geom);
  }

  Geometry reduceArea(Geometry geom) {
    return PrecisionReducer.reducePrecision(geom, targetPM);
  }
}
