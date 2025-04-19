import 'package:d_util/d_util.dart';
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

  PrecisionModel targetPM;

  final bool _isRemoveCollapsed;

  PrecisionReducerTransformer(this.targetPM, this._isRemoveCollapsed);

  @override
  CoordinateSequence? transformCoordinates(CoordinateSequence coordinates, Geometry? parent) {
    if (coordinates.size() == 0) {
      return null;
    }

    Array<Coordinate> coordsReduce = reduceCompress(coordinates);
    int minSize = 0;
    if (parent is LineString) {
      minSize = 2;
    }

    if (parent is LinearRing) {
      minSize = LinearRing.MINIMUM_VALID_SIZE;
    }

    if (coordsReduce.length < minSize) {
      if (_isRemoveCollapsed) {
        return null;
      }
      coordsReduce = extend(coordsReduce, minSize);
    }
    return factory.csFactory.create(coordsReduce);
  }

  Array<Coordinate> extend(Array<Coordinate> coords, int minLength) {
    if (coords.length >= minLength) {
      return coords;
    }

    Array<Coordinate> exCoords = Array(minLength);
    for (int i = 0; i < exCoords.length; i++) {
      int iSrc = (i < coords.length) ? i : coords.length - 1;
      exCoords[i] = coords[iSrc].copy();
    }
    return exCoords;
  }

  Array<Coordinate> reduceCompress(CoordinateSequence coordinates) {
    CoordinateList noRepeatCoordList = CoordinateList();
    for (int i = 0; i < coordinates.size(); i++) {
      Coordinate coord = coordinates.getCoordinate(i).copy();
      targetPM.makePrecise(coord);
      noRepeatCoordList.add3(coord, false);
    }
    Array<Coordinate> noRepeatCoords = noRepeatCoordList.toCoordinateArray();
    return noRepeatCoords;
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
