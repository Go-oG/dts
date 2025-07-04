import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';

import 'common_bits.dart';

class CommonBitsRemover {
  late Coordinate _commonCoord;

  final _ccFilter = CommonCoordinateFilter();

  void add(Geometry geom) {
    geom.apply(_ccFilter);
    _commonCoord = _ccFilter.getCommonCoordinate();
  }

  Coordinate getCommonCoordinate() {
    return _commonCoord;
  }

  Geometry removeCommonBits(Geometry geom) {
    if ((_commonCoord.x == 0.0) && (_commonCoord.y == 0.0)) {
      return geom;
    }

    Coordinate invCoord = Coordinate.of(_commonCoord);
    invCoord.x = -invCoord.x;
    invCoord.y = -invCoord.y;
    final trans = Translater(invCoord);
    geom.apply2(trans);
    geom.geometryChanged();
    return geom;
  }

  void addCommonBits(Geometry geom) {
    Translater trans = Translater(_commonCoord);
    geom.apply2(trans);
    geom.geometryChanged();
  }
}

class Translater implements CoordinateSequenceFilter {
  Coordinate trans;

  Translater(this.trans);

  @override
  void filter(CoordinateSequence seq, int i) {
    double xp = seq.getOrdinate(i, 0) + trans.x;
    double yp = seq.getOrdinate(i, 1) + trans.y;
    seq.setOrdinate(i, 0, xp);
    seq.setOrdinate(i, 1, yp);
  }

  @override
  bool isDone() {
    return false;
  }

  @override
  bool isGeometryChanged() {
    return true;
  }
}

class CommonCoordinateFilter implements CoordinateFilter {
  final _commonBitsX = CommonBits();

  final _commonBitsY = CommonBits();

  @override
  void filter(Coordinate coord) {
    _commonBitsX.add(coord.x);
    _commonBitsY.add(coord.y);
  }

  Coordinate getCommonCoordinate() {
    return Coordinate(_commonBitsX.getCommon(), _commonBitsY.getCommon());
  }
}
