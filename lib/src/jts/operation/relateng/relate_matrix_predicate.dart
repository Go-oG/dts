import 'package:dts/src/jts/geom/intersection_matrix.dart';

import 'impredicate.dart';

class RelateMatrixPredicate extends IMPredicate {
  @override
  String name() {
    return "relateMatrix";
  }

  @override
  bool requireInteraction() {
    return false;
  }

  @override
  bool isDetermined() {
    return false;
  }

  @override
  bool valueIM() {
    return false;
  }

  IntersectionMatrix getIM() {
    return intMatrix;
  }
}
