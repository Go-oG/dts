import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';

import 'coverage_polygon_validator.dart';

class CoverageValidator {
  static bool isValid(List<Geometry> coverage, [double? gapWidth]) {
    final v = CoverageValidator(coverage);
    if (gapWidth != null) {
      v.setGapWidth(gapWidth);
    }
    return !hasInvalidResult(v.validate());
  }

  static bool hasInvalidResult(List<Geometry?> validateResult) {
    for (Geometry? geom in validateResult) {
      if (geom != null) {
        return true;
      }
    }
    return false;
  }

  static List<Geometry> validateS(List<Geometry> coverage) {
    CoverageValidator v = CoverageValidator(coverage);
    return v.validate();
  }

  static List<Geometry> validateS2(List<Geometry> coverage, double gapWidth) {
    CoverageValidator v = CoverageValidator(coverage);
    v.setGapWidth(gapWidth);
    return v.validate();
  }

  List<Geometry> coverage;

  double _gapWidth = 0;

  CoverageValidator(this.coverage);

  void setGapWidth(double gapWidth) {
    _gapWidth = gapWidth;
  }

  List<Geometry> validate() {
    STRtree<Geometry> index = STRtree();
    for (Geometry geom in coverage) {
      index.insert(geom.getEnvelopeInternal(), geom);
    }
    List<Geometry> invalidLines = [];
    for (int i = 0; i < coverage.length; i++) {
      Geometry geom = coverage[i];
      invalidLines.add(_validate(geom, index)!);
    }
    return invalidLines;
  }

  Geometry? _validate(Geometry targetGeom, STRtree<Geometry> index) {
    Envelope queryEnv = targetGeom.getEnvelopeInternal();
    queryEnv.expandBy(_gapWidth);
    List<Geometry> nearGeomList = index.query(queryEnv);
    nearGeomList.remove(targetGeom);
    Geometry result = CoveragePolygonValidator.validateS2(
        targetGeom, nearGeomList, _gapWidth);
    return result.isEmpty() ? null : result;
  }
}
