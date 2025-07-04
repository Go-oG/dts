import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/util/geometry_transformer.dart';

import 'line_string_snapper.dart';

class SnapTransformer extends GeometryTransformer {
  double snapTolerance;
  final Array<Coordinate> _snapPts;
  final bool _isSelfSnap;

  SnapTransformer(this.snapTolerance, this._snapPts, [this._isSelfSnap = false]);

  @override
  CoordinateSequence? transformCoordinates(CoordinateSequence coords, Geometry? parent) {
    Array<Coordinate> srcPts = coords.toCoordinateArray();
    Array<Coordinate> newPts = snapLine(srcPts, _snapPts);
    return factory.csFactory.create(newPts);
  }

  Array<Coordinate> snapLine(Array<Coordinate> srcPts, Array<Coordinate> snapPts) {
    final snapper = LineStringSnapper(srcPts, snapTolerance);
    snapper.setAllowSnappingToSourceVertices(_isSelfSnap);
    return snapper.snapTo(snapPts);
  }
}
