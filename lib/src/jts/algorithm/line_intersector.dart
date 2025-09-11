import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/math/math.dart';
import 'package:dts/src/jts/util/assert.dart';

abstract class LineIntersector {
  static const int kDontIntersect = 0;
  static const int kDoIntersect = 1;
  static const int kCollinear = 2;

  static const int kNoIntersection = 0;
  static const int kPointIntersection = 1;
  static const int kCollinearIntersection = 2;

  static double computeEdgeDistance(
      Coordinate p, Coordinate p0, Coordinate p1) {
    double dx = Math.abs(p1.x - p0.x);
    double dy = Math.abs(p1.y - p0.y);
    double dist = -1.0;
    if (p == (p0)) {
      dist = 0.0;
    } else if (p == (p1)) {
      if (dx > dy) {
        dist = dx;
      } else {
        dist = dy;
      }
    } else {
      double pdx = Math.abs(p.x - p0.x);
      double pdy = Math.abs(p.y - p0.y);
      if (dx > dy) {
        dist = pdx;
      } else {
        dist = pdy;
      }

      if ((dist == 0.0) && p != p0) {
        dist = Math.maxD(pdx, pdy);
      }
    }
    Assert.isTrue(!((dist == 0.0) && p != p0), "Bad distance calculation");
    return dist;
  }

  static double nonRobustComputeEdgeDistance(
      Coordinate p, Coordinate p1, Coordinate p2) {
    double dx = p.x - p1.x;
    double dy = p.y - p1.y;
    double dist = MathUtil.hypot(dx, dy);
    Assert.isTrue(!(dist == 0.0 && p != p1), "Invalid distance calculation");
    return dist;
  }

  int result = 0;

  Array<Array<Coordinate>> inputLines = Array.matrix(2);

  Array<Coordinate> intPt = Array<Coordinate>(2);

  Array<Array<int>>? intLineIndex;

  bool isProper = false;

  late Coordinate pa;

  late Coordinate pb;

  PrecisionModel? precisionModel;

  LineIntersector() {
    intPt[0] = Coordinate();
    intPt[1] = Coordinate();
    pa = intPt[0];
    pb = intPt[1];
    result = 0;
  }

  void setMakePrecise(PrecisionModel precisionModel) {
    this.precisionModel = precisionModel;
  }

  void setPrecisionModel(PrecisionModel precisionModel) {
    this.precisionModel = precisionModel;
  }

  Coordinate getEndpoint(int segmentIndex, int ptIndex) {
    return inputLines[segmentIndex][ptIndex];
  }

  void computeIntersection(Coordinate p, Coordinate p1, Coordinate p2);

  bool isCollinear() {
    return result == kCollinearIntersection;
  }

  void computeIntersection2(
      Coordinate p1, Coordinate p2, Coordinate p3, Coordinate p4) {
    inputLines[0][0] = p1;
    inputLines[0][1] = p2;
    inputLines[1][0] = p3;
    inputLines[1][1] = p4;
    result = computeIntersect(p1, p2, p3, p4);
  }

  int computeIntersect(
      Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2);

  bool isEndPoint() {
    return hasIntersection() && (!isProper);
  }

  bool hasIntersection() {
    return result != kNoIntersection;
  }

  int getIntersectionNum() {
    return result;
  }

  Coordinate getIntersection(int intIndex) {
    return intPt[intIndex];
  }

  void computeIntLineIndex() {
    if (intLineIndex == null) {
      intLineIndex = Array.matrix(2);
      computeIntLineIndex2(0);
      computeIntLineIndex2(1);
    }
  }

  bool isIntersection(Coordinate pt) {
    for (int i = 0; i < result; i++) {
      if (intPt[i].equals2D(pt)) {
        return true;
      }
    }
    return false;
  }

  bool isInteriorIntersection() {
    if (isInteriorIntersection2(0)) {
      return true;
    }

    if (isInteriorIntersection2(1)) {
      return true;
    }

    return false;
  }

  bool isInteriorIntersection2(int inputLineIndex) {
    for (int i = 0; i < result; i++) {
      if (!(intPt[i].equals2D(inputLines[inputLineIndex][0]) ||
          intPt[i].equals2D(inputLines[inputLineIndex][1]))) {
        return true;
      }
    }
    return false;
  }

  bool isProperF() {
    return hasIntersection() && isProper;
  }

  Coordinate getIntersectionAlongSegment(int segmentIndex, int intIndex) {
    computeIntLineIndex();
    return intPt[intLineIndex![segmentIndex][intIndex]];
  }

  int getIndexAlongSegment(int segmentIndex, int intIndex) {
    computeIntLineIndex();
    return intLineIndex![segmentIndex][intIndex];
  }

  void computeIntLineIndex2(int segmentIndex) {
    double dist0 = getEdgeDistance(segmentIndex, 0);
    double dist1 = getEdgeDistance(segmentIndex, 1);
    if (dist0 > dist1) {
      intLineIndex![segmentIndex][0] = 0;
      intLineIndex![segmentIndex][1] = 1;
    } else {
      intLineIndex![segmentIndex][0] = 1;
      intLineIndex![segmentIndex][1] = 0;
    }
  }

  double getEdgeDistance(int segmentIndex, int intIndex) {
    double dist = computeEdgeDistance(intPt[intIndex],
        inputLines[segmentIndex][0], inputLines[segmentIndex][1]);
    return dist;
  }
}
