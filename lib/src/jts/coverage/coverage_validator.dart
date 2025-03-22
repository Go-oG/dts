 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';

import 'coverage_polygon_validator.dart';

class CoverageValidator {
  static bool isValid(Array<Geometry> coverage) {
    CoverageValidator v = CoverageValidator(coverage);
    return !hasInvalidResult(v.validate());
  }

  static bool isValid2(Array<Geometry> coverage, double gapWidth) {
    CoverageValidator v = CoverageValidator(coverage);
    v.setGapWidth(gapWidth);
    return !hasInvalidResult(v.validate());
  }

  static bool hasInvalidResult(Array<Geometry?> validateResult) {
    for (Geometry? geom in validateResult) {
      if (geom != null) {
        return true;
      }
    }
    return false;
  }

  static Array<Geometry> validateS(Array<Geometry> coverage) {
    CoverageValidator v = CoverageValidator(coverage);
    return v.validate();
  }

  static Array<Geometry> validateS2(Array<Geometry> coverage, double gapWidth) {
    CoverageValidator v = CoverageValidator(coverage);
    v.setGapWidth(gapWidth);
    return v.validate();
  }

  Array<Geometry> coverage;

  double _gapWidth = 0;

  CoverageValidator(this.coverage);

  void setGapWidth(double gapWidth) {
    _gapWidth = gapWidth;
  }

  Array<Geometry> validate() {
    STRtree<Geometry> index = STRtree();
    for (Geometry geom in coverage) {
      index.insert(geom.getEnvelopeInternal(), geom);
    }
    Array<Geometry> invalidLines = Array<Geometry>(coverage.length);
    for (int i = 0; i < coverage.length; i++) {
      Geometry geom = coverage[i];
      invalidLines[i] = _validate(geom, index)!;
    }
    return invalidLines;
  }

  Geometry? _validate(Geometry targetGeom, STRtree<Geometry> index) {
    Envelope queryEnv = targetGeom.getEnvelopeInternal();
    queryEnv.expandBy(_gapWidth);
    List<Geometry> nearGeomList = index.query(queryEnv);
    nearGeomList.remove(targetGeom);
    Array<Geometry>? nearGeoms = GeometryFactory.toGeometryArray(nearGeomList);
    Geometry result = CoveragePolygonValidator.validateS2(targetGeom, nearGeoms!, _gapWidth);
    return result.isEmpty() ? null : result;
  }
}
