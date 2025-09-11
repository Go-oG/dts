import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/line_string.dart';

import '../geom/coordinate.dart';
import '../geom/geometry.dart';
import 'linear_location.dart';
import 'location_index_of_point.dart';

class LocationIndexOfLine {
  static Array<LinearLocation> indicesOf2(
      Geometry linearGeom, Geometry subLine) {
    LocationIndexOfLine locater = LocationIndexOfLine(linearGeom);
    return locater.indicesOf(subLine);
  }

  Geometry linearGeom;

  LocationIndexOfLine(this.linearGeom);

  Array<LinearLocation> indicesOf(Geometry subLine) {
    Coordinate startPt =
        (subLine.getGeometryN(0) as LineString).getCoordinateN(0);
    LineString lastLine =
        (subLine.getGeometryN(subLine.getNumGeometries() - 1) as LineString);
    Coordinate endPt = lastLine.getCoordinateN(lastLine.getNumPoints() - 1);
    LocationIndexOfPoint locPt = LocationIndexOfPoint(linearGeom);
    Array<LinearLocation> subLineLoc = Array(2);
    subLineLoc[0] = locPt.indexOf(startPt);
    if (subLine.getLength() == 0.0) {
      subLineLoc[1] = subLineLoc[0].copy();
    } else {
      subLineLoc[1] = locPt.indexOfAfter(endPt, subLineLoc[0]);
    }
    return subLineLoc;
  }
}
