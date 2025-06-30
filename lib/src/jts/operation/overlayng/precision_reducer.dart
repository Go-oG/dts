import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/precision_model.dart';

import 'overlay_ng.dart';

class PrecisionReducer {
  static Geometry reducePrecision(Geometry geom, PrecisionModel pm) {
    OverlayNG ov = OverlayNG.of(geom, pm);
    if (geom.getDimension() == 2) {
      ov.setAreaResultOnly(true);
    }
    try {
      Geometry reduced = ov.getResult();
      return reduced;
    } catch (ex) {
      throw ("Reduction failed, possible invalid input");
    }
  }
}
