import 'package:dts/src/jts/geom/line_string.dart';

import '../geom/coordinate.dart';
import '../geom/geometry.dart';
import 'linear_location.dart';
import 'location_index_of_point.dart';

class LocationIndexOfLine {
  static List<LinearLocation> indicesOf2(Geometry linearGeom, Geometry subLine) {
    return LocationIndexOfLine(linearGeom).indicesOf(subLine);
  }

  Geometry linearGeom;
  LocationIndexOfLine(this.linearGeom);

  List<LinearLocation> indicesOf(Geometry subLine) {
    Coordinate startPt = (subLine.getGeometryN(0) as LineString).getCoordinateN(0);
    LineString lastLine = (subLine.getGeometryN(subLine.getNumGeometries() - 1) as LineString);
    Coordinate endPt = lastLine.getCoordinateN(lastLine.getNumPoints() - 1);
    LocationIndexOfPoint locPt = LocationIndexOfPoint(linearGeom);
    List<LinearLocation> subLineLoc = [locPt.indexOf(startPt)];
    if (subLine.getLength() == 0.0) {
      subLineLoc.add(subLineLoc[0].copy());
    } else {
      subLineLoc.add(locPt.indexOfAfter(endPt, subLineLoc[0]));
    }
    return subLineLoc;
  }
}
