import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'linear_iterator.dart';

class LengthIndexOfPoint {
  static double indexOf2(Geometry linearGeom, Coordinate inputPt) {
    LengthIndexOfPoint locater = LengthIndexOfPoint(linearGeom);
    return locater.indexOf(inputPt);
  }

  static double indexOfAfter2(Geometry linearGeom, Coordinate inputPt, double minIndex) {
    LengthIndexOfPoint locater = LengthIndexOfPoint(linearGeom);
    return locater.indexOfAfter(inputPt, minIndex);
  }

  final Geometry _linearGeom;

  LengthIndexOfPoint(this._linearGeom);

  double indexOf(Coordinate inputPt) {
    return indexOfFromStart(inputPt, -1.0);
  }

  double indexOfAfter(Coordinate inputPt, double minIndex) {
    if (minIndex < 0.0) return indexOf(inputPt);

    double endIndex = _linearGeom.getLength();
    if (endIndex < minIndex) return endIndex;

    double closestAfter = indexOfFromStart(inputPt, minIndex);
    Assert.isTrue2(closestAfter >= minIndex, "computed index is before specified minimum index");
    return closestAfter;
  }

  double indexOfFromStart(Coordinate inputPt, double minIndex) {
    double minDistance = double.maxFinite;
    double ptMeasure = minIndex;
    double segmentStartMeasure = 0.0;
    LineSegment seg = LineSegment.empty();
    LinearIterator it = LinearIterator.of(_linearGeom);
    while (it.hasNext()) {
      if (!it.isEndOfLine()) {
        seg.p0 = it.getSegmentStart();
        seg.p1 = it.getSegmentEnd()!;
        double segDistance = seg.distance(inputPt);
        double segMeasureToPt = segmentNearestMeasure(seg, inputPt, segmentStartMeasure);
        if ((segDistance < minDistance) && (segMeasureToPt > minIndex)) {
          ptMeasure = segMeasureToPt;
          minDistance = segDistance;
        }
        segmentStartMeasure += seg.getLength();
      }
      it.next();
    }
    return ptMeasure;
  }

  double segmentNearestMeasure(LineSegment seg, Coordinate inputPt, double segmentStartMeasure) {
    double projFactor = seg.projectionFactor(inputPt);
    if (projFactor <= 0.0) return segmentStartMeasure;

    if (projFactor <= 1.0) return segmentStartMeasure + (projFactor * seg.getLength());

    return segmentStartMeasure + seg.getLength();
  }
}
