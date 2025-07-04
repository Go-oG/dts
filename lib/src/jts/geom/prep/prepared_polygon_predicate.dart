import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygonal.dart';
import 'package:dts/src/jts/geom/util/component_coordinate_extracter.dart';
import 'package:dts/src/jts/noding/segment_string_util.dart';

import 'prepared_geometry.dart';

abstract class PreparedPolygonPredicate {
  PreparedPolygon prepPoly;

  late PointOnGeometryLocator _targetPointLocator;

  PreparedPolygonPredicate(this.prepPoly) {
    _targetPointLocator = prepPoly.getPointLocator();
  }

  bool isAllTestComponentsInTarget(Geometry testGeom) {
    List<Coordinate> coords = ComponentCoordinateExtracter.getCoordinates(testGeom);
    for (var p in coords) {
      int loc = _targetPointLocator.locate(p);
      if (loc == Location.exterior) return false;
    }
    return true;
  }

  bool isAllTestComponentsInTargetInterior(Geometry testGeom) {
    final coords = ComponentCoordinateExtracter.getCoordinates(testGeom);
    for (var p in coords) {
      int loc = _targetPointLocator.locate(p);
      if (loc != Location.interior) return false;
    }
    return true;
  }

  bool isAnyTestComponentInTarget(Geometry testGeom) {
    final coords = ComponentCoordinateExtracter.getCoordinates(testGeom);
    for (var p in coords) {
      int loc = _targetPointLocator.locate(p);
      if (loc != Location.exterior) return true;
    }
    return false;
  }

  bool isAllTestPointsInTarget(Geometry testGeom) {
    for (int i = 0; i < testGeom.getNumGeometries(); i++) {
      Point pt = (testGeom.getGeometryN(i) as Point);
      Coordinate? p = pt.getCoordinate();
      int loc = _targetPointLocator.locate(p!);
      if (loc == Location.exterior) return false;
    }
    return true;
  }

  bool isAnyTestPointInTargetInterior(Geometry testGeom) {
    for (int i = 0; i < testGeom.getNumGeometries(); i++) {
      Point pt = testGeom.getGeometryN(i) as Point;
      Coordinate p = pt.getCoordinate()!;
      int loc = _targetPointLocator.locate(p);
      if (loc == Location.interior) return true;
    }
    return false;
  }

  bool isAnyTargetComponentInAreaTest(Geometry testGeom, List<Coordinate> targetRepPts) {
    final piaLoc = SimplePointInAreaLocator(testGeom);
    for (var p in targetRepPts) {
      int loc = piaLoc.locate(p);
      if (loc != Location.exterior) return true;
    }

    return false;
  }
}

class PreparedPolygonContainsProperly extends PreparedPolygonPredicate {
  static bool containsProperlyS(PreparedPolygon prep, Geometry geom) {
    PreparedPolygonContainsProperly polyInt = PreparedPolygonContainsProperly(prep);
    return polyInt.containsProperly(geom);
  }

  PreparedPolygonContainsProperly(super.prepPoly);

  bool containsProperly(Geometry geom) {
    bool isAllInPrepGeomAreaInterior = isAllTestComponentsInTargetInterior(geom);
    if (!isAllInPrepGeomAreaInterior) return false;

    final lineSegStr = SegmentStringUtil.extractSegmentStrings(geom);
    bool segsIntersect = prepPoly.getIntersectionFinder().intersects(lineSegStr);
    if (segsIntersect) return false;

    if (geom is Polygonal) {
      bool isTargetGeomInTestArea =
          isAnyTargetComponentInAreaTest(geom, prepPoly.getRepresentativePoints());
      if (isTargetGeomInTestArea) return false;
    }
    return true;
  }
}

class PreparedPolygonIntersects extends PreparedPolygonPredicate {
  static bool intersectsS(PreparedPolygon prep, Geometry geom) {
    PreparedPolygonIntersects polyInt = PreparedPolygonIntersects(prep);
    return polyInt.intersects(geom);
  }

  PreparedPolygonIntersects(super.prepPoly);

  bool intersects(Geometry geom) {
    bool isInPrepGeomArea = isAnyTestComponentInTarget(geom);
    if (isInPrepGeomArea) return true;

    if (geom.getDimension() == 0) return false;

    final lineSegStr = SegmentStringUtil.extractSegmentStrings(geom);
    if (lineSegStr.isNotEmpty) {
      bool segsIntersect = prepPoly.getIntersectionFinder().intersects(lineSegStr);
      if (segsIntersect) return true;
    }
    if (geom.getDimension() == 2) {
      bool isPrepGeomInArea =
          isAnyTargetComponentInAreaTest(geom, prepPoly.getRepresentativePoints());
      if (isPrepGeomInArea) return true;
    }
    return false;
  }
}
