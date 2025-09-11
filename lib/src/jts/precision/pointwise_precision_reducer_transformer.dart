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

  final PrecisionModel targetPM;

  PointwisePrecisionReducerTransformer(this.targetPM);

  @override
  CoordinateSequence? transformCoordinates(CoordinateSequence coords, Geometry? parent) {
    if (coords.size() == 0) {
      return null;
    }

    final coordsReduce = reducePointwise(coords);
    return factory.csFactory.create(coordsReduce);
  }

  List<Coordinate> reducePointwise(CoordinateSequence coordinates) {
    List<Coordinate> coordReduce = [];
    for (int i = 0; i < coordinates.size(); i++) {
      Coordinate coord = coordinates.getCoordinate(i).copy();
      targetPM.makePrecise(coord);
      coordReduce.add(coord);
    }
    return coordReduce;
  }
}
