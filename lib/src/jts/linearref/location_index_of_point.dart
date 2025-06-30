import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'linear_iterator.dart';
import 'linear_location.dart';

class LocationIndexOfPoint {
  static LinearLocation indexOf2(Geometry linearGeom, Coordinate inputPt) {
    LocationIndexOfPoint locater = LocationIndexOfPoint(linearGeom);
    return locater.indexOf(inputPt);
  }

  static LinearLocation indexOfAfter2(
      Geometry linearGeom, Coordinate inputPt, LinearLocation minIndex) {
    LocationIndexOfPoint locater = LocationIndexOfPoint(linearGeom);
    return locater.indexOfAfter(inputPt, minIndex);
  }

  Geometry linearGeom;

  LocationIndexOfPoint(this.linearGeom);

  LinearLocation indexOf(Coordinate inputPt) {
    return indexOfFromStart(inputPt, null);
  }

  LinearLocation indexOfAfter(Coordinate inputPt, LinearLocation? minIndex) {
    if (minIndex == null) {
      return indexOf(inputPt);
    }

    LinearLocation endLoc = LinearLocation.getEndLocation(linearGeom);
    if (endLoc.compareTo(minIndex) <= 0) {
      return endLoc;
    }

    LinearLocation closestAfter = indexOfFromStart(inputPt, minIndex);
    Assert.isTrue2(closestAfter.compareTo(minIndex) >= 0,
        "computed location is before specified minimum location");
    return closestAfter;
  }

  LinearLocation indexOfFromStart(Coordinate inputPt, LinearLocation? minIndex) {
    double minDistance = double.maxFinite;
    int minComponentIndex = 0;
    int minSegmentIndex = 0;
    double minFrac = -1.0;
    LineSegment seg = LineSegment.empty();
    for (LinearIterator it = LinearIterator.of(linearGeom); it.hasNext(); it.next()) {
      if (!it.isEndOfLine()) {
        seg.p0 = it.getSegmentStart();
        seg.p1 = it.getSegmentEnd()!;
        double segDistance = seg.distance(inputPt);
        double segFrac = seg.segmentFraction(inputPt);
        int candidateComponentIndex = it.getComponentIndex();
        int candidateSegmentIndex = it.getVertexIndex();
        if (segDistance < minDistance) {
          if ((minIndex == null) ||
              (minIndex.compareLocationValues(
                      candidateComponentIndex, candidateSegmentIndex, segFrac) <
                  0)) {
            minComponentIndex = candidateComponentIndex;
            minSegmentIndex = candidateSegmentIndex;
            minFrac = segFrac;
            minDistance = segDistance;
          }
        }
      }
    }
    if (minDistance == double.maxFinite) {
      return LinearLocation.of3(minIndex!);
    }
    LinearLocation loc = LinearLocation(minComponentIndex, minSegmentIndex, minFrac);
    return loc;
  }
}
