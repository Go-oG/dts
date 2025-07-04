import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';

import 'extract_line_by_location.dart';
import 'linear_location.dart';
import 'location_index_of_line.dart';
import 'location_index_of_point.dart';

class LocationIndexedLine {
  Geometry linearGeom;

  LocationIndexedLine(this.linearGeom) {
    checkGeometryType();
  }

  void checkGeometryType() {
    if (!((linearGeom is LineString) || (linearGeom is MultiLineString))) {
      throw ("Input geometry must be linear");
    }
  }

  Coordinate extractPoint(LinearLocation index) {
    return index.getCoordinate(linearGeom);
  }

  Coordinate extractPoint2(LinearLocation index, double offsetDistance) {
    LinearLocation indexLow = index.toLowest(linearGeom);
    return indexLow
        .getSegment(linearGeom)
        .pointAlongOffset(indexLow.getSegmentFraction(), offsetDistance);
  }

  Geometry extractLine(LinearLocation startIndex, LinearLocation endIndex) {
    return ExtractLineByLocation.extract(linearGeom, startIndex, endIndex);
  }

  LinearLocation indexOf(Coordinate pt) {
    return LocationIndexOfPoint.indexOf2(linearGeom, pt);
  }

  LinearLocation indexOfAfter(Coordinate pt, LinearLocation minIndex) {
    return LocationIndexOfPoint.indexOfAfter2(linearGeom, pt, minIndex);
  }

  Array<LinearLocation> indicesOf(Geometry subLine) {
    return LocationIndexOfLine.indicesOf2(linearGeom, subLine);
  }

  LinearLocation project(Coordinate pt) {
    return LocationIndexOfPoint.indexOf2(linearGeom, pt);
  }

  LinearLocation getStartIndex() {
    return LinearLocation.empty();
  }

  LinearLocation getEndIndex() {
    return LinearLocation.getEndLocation(linearGeom);
  }

  bool isValidIndex(LinearLocation index) {
    return index.isValid(linearGeom);
  }

  LinearLocation clampIndex(LinearLocation index) {
    LinearLocation loc = index.copy();
    loc.clamp(linearGeom);
    return loc;
  }
}
