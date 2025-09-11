import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geom/precision_model.dart';

import 'buffer_input_line_simplifier.dart';
import 'buffer_parameters.dart';
import 'offset_segment_generator.dart';

class OffsetCurveBuilder {
  double _distance = 0.0;

  PrecisionModel precisionModel;

  BufferParameters bufParams;

  OffsetCurveBuilder(this.precisionModel, this.bufParams);

  BufferParameters getBufferParameters() {
    return bufParams;
  }

  List<Coordinate>? getLineCurve(List<Coordinate> inputPts, double distance) {
    _distance = distance;
    if (isLineOffsetEmpty(distance)) {
      return null;
    }

    double posDistance = distance.abs();
    OffsetSegmentGenerator segGen = getSegGen(posDistance);
    if (inputPts.length <= 1) {
      computePointCurve(inputPts[0], segGen);
    } else if (bufParams.isSingleSided()) {
      bool isRightSide = distance < 0.0;
      computeSingleSidedBufferCurve(inputPts, isRightSide, segGen);
    } else {
      computeLineBufferCurve(inputPts, segGen);
    }

    return segGen.getCoordinates();
  }

  bool isLineOffsetEmpty(double distance) {
    if (distance == 0.0) {
      return true;
    }

    if ((distance < 0.0) && (!bufParams.isSingleSided())) {
      return true;
    }

    return false;
  }

  List<Coordinate>? getRingCurve(
      List<Coordinate> inputPts, int side, double distance) {
    _distance = distance;
    if (inputPts.length <= 2) {
      return getLineCurve(inputPts, distance);
    }

    if (distance == 0.0) {
      return copyCoordinates(inputPts);
    }
    OffsetSegmentGenerator segGen = getSegGen(distance);
    computeRingBufferCurve(inputPts, side, segGen);
    return segGen.getCoordinates();
  }

  List<Coordinate>? getOffsetCurve(List<Coordinate> inputPts, double distance) {
    _distance = distance;
    if (distance == 0.0) {
      return null;
    }

    bool isRightSide = distance < 0.0;
    double posDistance = distance.abs();
    OffsetSegmentGenerator segGen = getSegGen(posDistance);
    if (inputPts.length <= 1) {
      computePointCurve(inputPts[0], segGen);
    } else {
      computeOffsetCurve(inputPts, isRightSide, segGen);
    }
    List<Coordinate> curvePts = segGen.getCoordinates();
    if (isRightSide) {
      CoordinateArrays.reverse(curvePts);
    }
    return curvePts;
  }

  static List<Coordinate> copyCoordinates(List<Coordinate> pts) =>
      pts.map((e) => e.copy()).toList();

  OffsetSegmentGenerator getSegGen(double distance) {
    return OffsetSegmentGenerator(precisionModel, bufParams, distance);
  }

  double simplifyTolerance(double bufDistance) {
    return bufDistance * bufParams.getSimplifyFactor();
  }

  void computePointCurve(Coordinate pt, OffsetSegmentGenerator segGen) {
    switch (bufParams.getEndCapStyle()) {
      case BufferParameters.kCapRound:
        segGen.createCircle(pt);
        break;
      case BufferParameters.kCapSquare:
        segGen.createSquare(pt);
        break;
    }
  }

  void computeLineBufferCurve(
      List<Coordinate> inputPts, OffsetSegmentGenerator segGen) {
    double distTol = simplifyTolerance(_distance);
    final simp1 = BufferInputLineSimplifier.simplify2(inputPts, distTol);
    int n1 = simp1.length - 1;
    segGen.initSideSegments(simp1[0], simp1[1], Position.left);
    for (int i = 2; i <= n1; i++) {
      segGen.addNextSegment(simp1[i], true);
    }
    segGen.addLastSegment();
    segGen.addLineEndCap(simp1[n1 - 1], simp1[n1]);
    final simp2 = BufferInputLineSimplifier.simplify2(inputPts, -distTol);
    int n2 = simp2.length - 1;
    segGen.initSideSegments(simp2[n2], simp2[n2 - 1], Position.left);
    for (int i = n2 - 2; i >= 0; i--) {
      segGen.addNextSegment(simp2[i], true);
    }
    segGen.addLastSegment();
    segGen.addLineEndCap(simp2[1], simp2[0]);
    segGen.closeRing();
  }

  void computeSingleSidedBufferCurve(List<Coordinate> inputPts,
      bool isRightSide, OffsetSegmentGenerator segGen) {
    double distTol = simplifyTolerance(_distance);
    if (isRightSide) {
      segGen.addSegments(inputPts, true);
      final simp2 = BufferInputLineSimplifier.simplify2(inputPts, -distTol);
      int n2 = simp2.length - 1;
      segGen.initSideSegments(simp2[n2], simp2[n2 - 1], Position.left);
      segGen.addFirstSegment();
      for (int i = n2 - 2; i >= 0; i--) {
        segGen.addNextSegment(simp2[i], true);
      }
    } else {
      segGen.addSegments(inputPts, false);
      final simp1 = BufferInputLineSimplifier.simplify2(inputPts, distTol);
      int n1 = simp1.length - 1;
      segGen.initSideSegments(simp1[0], simp1[1], Position.left);
      segGen.addFirstSegment();
      for (int i = 2; i <= n1; i++) {
        segGen.addNextSegment(simp1[i], true);
      }
    }
    segGen.addLastSegment();
    segGen.closeRing();
  }

  void computeOffsetCurve(List<Coordinate> inputPts, bool isRightSide,
      OffsetSegmentGenerator segGen) {
    double distTol = simplifyTolerance(_distance.abs());
    if (isRightSide) {
      final simp2 = BufferInputLineSimplifier.simplify2(inputPts, -distTol);
      int n2 = simp2.length - 1;
      segGen.initSideSegments(simp2[n2], simp2[n2 - 1], Position.left);
      segGen.addFirstSegment();
      for (int i = n2 - 2; i >= 0; i--) {
        segGen.addNextSegment(simp2[i], true);
      }
    } else {
      final simp1 = BufferInputLineSimplifier.simplify2(inputPts, distTol);
      int n1 = simp1.length - 1;
      segGen.initSideSegments(simp1[0], simp1[1], Position.left);
      segGen.addFirstSegment();
      for (int i = 2; i <= n1; i++) {
        segGen.addNextSegment(simp1[i], true);
      }
    }
    segGen.addLastSegment();
  }

  void computeRingBufferCurve(
      List<Coordinate> inputPts, int side, OffsetSegmentGenerator segGen) {
    double distTol = simplifyTolerance(_distance);
    if (side == Position.right) {
      distTol = -distTol;
    }

    final simp = BufferInputLineSimplifier.simplify2(inputPts, distTol);
    int n = simp.length - 1;
    segGen.initSideSegments(simp[n - 1], simp[0], side);
    for (int i = 1; i <= n; i++) {
      bool addStartPoint = i != 1;
      segGen.addNextSegment(simp[i], addStartPoint);
    }
    segGen.closeRing();
  }
}
