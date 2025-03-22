import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/polygonal.dart';
import 'package:dts/src/jts/noding/segment_intersection_detector.dart';
import 'package:dts/src/jts/noding/segment_string_util.dart';

import 'prepared_geometry.dart';
import 'prepared_polygon_predicate.dart';

abstract class AbstractPreparedPolygonContains extends PreparedPolygonPredicate {
  bool requireSomePointInInterior = true;
  bool _hasSegmentIntersection = false;

  bool _hasProperIntersection = false;

  bool _hasNonProperIntersection = false;

  AbstractPreparedPolygonContains(super.prepPoly);

  bool eval(Geometry geom) {
    if (geom.getDimension() == 0) {
      return evalPoints(geom);
    }
    bool isAllInTargetArea = isAllTestComponentsInTarget(geom);
    if (!isAllInTargetArea) return false;

    bool properIntersectionImpliesNotContained = isProperIntersectionImpliesNotContainedSituation(geom);
    findAndClassifyIntersections(geom);
    if (properIntersectionImpliesNotContained && _hasProperIntersection) return false;

    if (_hasSegmentIntersection && (!_hasNonProperIntersection)) return false;

    if (_hasSegmentIntersection) {
      return fullTopologicalPredicate(geom);
    }
    if (geom is Polygonal) {
      bool isTargetInTestArea = isAnyTargetComponentInAreaTest(geom, prepPoly.getRepresentativePoints());
      if (isTargetInTestArea) return false;
    }
    return true;
  }

  bool evalPoints(Geometry geom) {
    bool isAllInTargetArea = isAllTestPointsInTarget(geom);
    if (!isAllInTargetArea) return false;

    if (requireSomePointInInterior) {
      bool isAnyInTargetInterior = isAnyTestPointInTargetInterior(geom);
      return isAnyInTargetInterior;
    }
    return true;
  }

  bool isProperIntersectionImpliesNotContainedSituation(Geometry testGeom) {
    if (testGeom is Polygonal) return true;

    if (isSingleShell(prepPoly.getGeometry())) return true;

    return false;
  }

  bool isSingleShell(Geometry geom) {
    if (geom.getNumGeometries() != 1) return false;

    Polygon poly = (geom.getGeometryN(0) as Polygon);
    int numHoles = poly.getNumInteriorRing();
    if (numHoles == 0) return true;

    return false;
  }

  void findAndClassifyIntersections(Geometry geom) {
    final lineSegStr = SegmentStringUtil.extractSegmentStrings(geom);
    SegmentIntersectionDetector intDetector = SegmentIntersectionDetector();
    intDetector.setFindAllIntersectionTypes(true);
    prepPoly.getIntersectionFinder().intersects2(lineSegStr, intDetector);
    _hasSegmentIntersection = intDetector.hasIntersection;
    _hasProperIntersection = intDetector.hasProperIntersection;
    _hasNonProperIntersection = intDetector.hasNonProperIntersection;
  }

  bool fullTopologicalPredicate(Geometry geom);
}

class PreparedPolygonContains extends AbstractPreparedPolygonContains {
  static bool containsS(PreparedPolygon prep, Geometry geom) {
    PreparedPolygonContains polyInt = PreparedPolygonContains(prep);
    return polyInt.contains(geom);
  }

  PreparedPolygonContains(super.prepPoly);

  bool contains(Geometry geom) {
    return eval(geom);
  }

  @override
  bool fullTopologicalPredicate(Geometry geom) {
    bool isContained = prepPoly.getGeometry().contains(geom);
    return isContained;
  }
}

class PreparedPolygonCovers extends AbstractPreparedPolygonContains {
  static bool coversS(PreparedPolygon prep, Geometry geom) {
    PreparedPolygonCovers polyInt = PreparedPolygonCovers(prep);
    return polyInt.covers(geom);
  }

  PreparedPolygonCovers(super.prepPoly) {
    requireSomePointInInterior = false;
  }

  bool covers(Geometry geom) {
    return eval(geom);
  }

  @override
  bool fullTopologicalPredicate(Geometry geom) {
    bool result = prepPoly.getGeometry().covers(geom);
    return result;
  }
}
