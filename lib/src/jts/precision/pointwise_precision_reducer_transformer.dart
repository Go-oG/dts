import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/util/geometry_transformer.dart';

class PointwisePrecisionReducerTransformer extends GeometryTransformer {
  static Geometry? reduce(Geometry geom, PrecisionModel targetPM) {
    PointwisePrecisionReducerTransformer trans = PointwisePrecisionReducerTransformer(targetPM);
    return trans.transform(geom);
  }

  PrecisionModel targetPM;

  PointwisePrecisionReducerTransformer(this.targetPM);

  @override
  CoordinateSequence? transformCoordinates(CoordinateSequence coordinates, Geometry? parent) {
    if (coordinates.size() == 0) {
      return null;
    }

    Array<Coordinate> coordsReduce = reducePointwise(coordinates);
    return factory.csFactory.create(coordsReduce);
  }

  Array<Coordinate> reducePointwise(CoordinateSequence coordinates) {
    Array<Coordinate> coordReduce = Array(coordinates.size());
    for (int i = 0; i < coordinates.size(); i++) {
      Coordinate coord = coordinates.getCoordinate(i).copy();
      targetPM.makePrecise(coord);
      coordReduce[i] = coord;
    }
    return coordReduce;
  }
}
