import 'package:dts/src/jts/geom/coordinate.dart';

class ConstraintEnforcementException {
  final String message;
  Coordinate? pt;

  ConstraintEnforcementException(this.message, [Coordinate? pt]) {
    if (pt != null) {
      this.pt = Coordinate.of(pt);
    }
  }

  Coordinate? getCoordinate() {
    return pt;
  }
}
