import '../../algorithm/point_locator.dart';
import '../../noding/segment_string_util.dart';
import '../geometry.dart';
import '../util/component_coordinate_extracter.dart';
import 'prepared_geometry.dart';

class PreparedLineStringIntersects {
  static bool intersectsS(PreparedLineString prep, Geometry geom) {
    PreparedLineStringIntersects op = PreparedLineStringIntersects(prep);
    return op.intersects(geom);
  }

  PreparedLineString prepLine;

  PreparedLineStringIntersects(this.prepLine);

  bool intersects(Geometry geom) {
    final lineSegStr = SegmentStringUtil.extractSegmentStrings(geom);
    if (lineSegStr.isNotEmpty) {
      bool segsIntersect = prepLine.getIntersectionFinder().intersects(lineSegStr);
      if (segsIntersect) return true;
    }
    if ((geom.getDimension() == 2) && prepLine.isAnyTargetComponentInTest(geom)) return true;

    if (geom.hasDimension(0)) return isAnyTestPointInTarget(geom);

    return false;
  }

  bool isAnyTestPointInTarget(Geometry testGeom) {
    PointLocator locator = PointLocator.empty();
    final coords = ComponentCoordinateExtracter.getCoordinates(testGeom);
    for (var p in coords) {
      if (locator.intersects(p, prepLine.getGeometry())) return true;
    }
    return false;
  }
}
