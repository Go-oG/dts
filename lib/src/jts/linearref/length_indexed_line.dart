import 'package:d_util/d_util.dart';

import '../geom/coordinate.dart';
import '../geom/geometry.dart';
import 'extract_line_by_location.dart';
import 'length_index_of_point.dart';
import 'length_location_map.dart';
import 'linear_location.dart';
import 'location_index_of_line.dart';

class LengthIndexedLine {
  Geometry linearGeom;

  LengthIndexedLine(this.linearGeom);

  Coordinate extractPoint(double index) {
    final loc = LengthLocationMap.getLocation3(linearGeom, index);
    return loc.getCoordinate(linearGeom);
  }

  Coordinate extractPoint2(double index, double offsetDistance) {
    final loc = LengthLocationMap.getLocation3(linearGeom, index);
    final locLow = loc.toLowest(linearGeom);
    return locLow
        .getSegment(linearGeom)
        .pointAlongOffset(locLow.getSegmentFraction(), offsetDistance);
  }

  Geometry extractLine(double startIndex, double endIndex) {
    double startIndex2 = clampIndex(startIndex);
    double endIndex2 = clampIndex(endIndex);
    bool resolveStartLower = startIndex2 == endIndex2;
    final startLoc = locationOf2(startIndex2, resolveStartLower);
    final endLoc = locationOf(endIndex2);
    return ExtractLineByLocation.extract(linearGeom, startLoc, endLoc);
  }

  LinearLocation locationOf(double index) {
    return LengthLocationMap.getLocation3(linearGeom, index);
  }

  LinearLocation locationOf2(double index, bool resolveLower) {
    return LengthLocationMap.getLocation4(linearGeom, index, resolveLower);
  }

  double indexOf(Coordinate pt) {
    return LengthIndexOfPoint.indexOf2(linearGeom, pt);
  }

  double indexOfAfter(Coordinate pt, double minIndex) {
    return LengthIndexOfPoint.indexOfAfter2(linearGeom, pt, minIndex);
  }

  Array<double> indicesOf(Geometry subLine) {
    Array<LinearLocation> locIndex = LocationIndexOfLine.indicesOf2(linearGeom, subLine);
    return [
      LengthLocationMap.getLength2(linearGeom, locIndex[0]),
      LengthLocationMap.getLength2(linearGeom, locIndex[1]),
    ].toArray();
  }

  double project(Coordinate pt) {
    return LengthIndexOfPoint.indexOf2(linearGeom, pt);
  }

  double getStartIndex() {
    return 0.0;
  }

  double getEndIndex() {
    return linearGeom.getLength();
  }

  bool isValidIndex(double index) {
    return (index >= getStartIndex()) && (index <= getEndIndex());
  }

  double clampIndex(double index) {
    double posIndex = positiveIndex(index);
    double startIndex = getStartIndex();
    if (posIndex < startIndex) return startIndex;

    double endIndex = getEndIndex();
    if (posIndex > endIndex) return endIndex;

    return posIndex;
  }

  double positiveIndex(double index) {
    if (index >= 0.0) return index;

    return linearGeom.getLength() + index;
  }
}
