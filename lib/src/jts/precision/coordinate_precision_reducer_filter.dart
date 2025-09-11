import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/precision_model.dart';

class CoordinatePrecisionReducerFilter implements CoordinateSequenceFilter {
  PrecisionModel precModel;

  CoordinatePrecisionReducerFilter(this.precModel);

  @override
  void filter(CoordinateSequence seq, int i) {
    seq.setOrdinate(i, 0, precModel.makePrecise2(seq.getOrdinate(i, 0)));
    seq.setOrdinate(i, 1, precModel.makePrecise2(seq.getOrdinate(i, 1)));
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
