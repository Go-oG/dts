import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

class NodingValidator {
  LineIntersector li = RobustLineIntersector();

  List<SegmentString> segStrings;

  static final GeomFactory _fact = GeomFactory();

  NodingValidator(this.segStrings);

  void checkValid() {
    checkEndPtVertexIntersections();
    checkInteriorIntersections();
    checkCollapses();
  }

  void checkCollapses() {
    for (var ss in segStrings) {
      checkCollapses2(ss);
    }
  }

  void checkCollapses2(SegmentString ss) {
    Array<Coordinate> pts = ss.getCoordinates();
    for (int i = 0; i < (pts.length - 2); i++) {
      checkCollapse(pts[i], pts[i + 1], pts[i + 2]);
    }
  }

  void checkCollapse(Coordinate p0, Coordinate p1, Coordinate p2) {
    if (p0 == p2) {
      throw "found non-noded collapse at ${_fact.createLineString2([p0, p1, p2].toArray())}";
    }
  }

  void checkInteriorIntersections() {
    for (var ss0 in segStrings) {
      for (var ss1 in segStrings) {
        checkInteriorIntersections3(ss0, ss1);
      }
    }
  }

  void checkInteriorIntersections3(SegmentString ss0, SegmentString ss1) {
    Array<Coordinate> pts0 = ss0.getCoordinates();
    Array<Coordinate> pts1 = ss1.getCoordinates();
    for (int i0 = 0; i0 < (pts0.length - 1); i0++) {
      for (int i1 = 0; i1 < (pts1.length - 1); i1++) {
        checkInteriorIntersections2(ss0, i0, ss1, i1);
      }
    }
  }

  void checkInteriorIntersections2(
      SegmentString e0, int segIndex0, SegmentString e1, int segIndex1) {
    if ((e0 == e1) && (segIndex0 == segIndex1)) return;

    Coordinate p00 = e0.getCoordinate(segIndex0);
    Coordinate p01 = e0.getCoordinate(segIndex0 + 1);
    Coordinate p10 = e1.getCoordinate(segIndex1);
    Coordinate p11 = e1.getCoordinate(segIndex1 + 1);
    li.computeIntersection2(p00, p01, p10, p11);
    if (li.hasIntersection()) {
      if ((li.isProper || hasInteriorIntersection(li, p00, p01)) ||
          hasInteriorIntersection(li, p10, p11)) {
        throw "found non-noded intersection at $p00-$p01 and $p10-$p11";
      }
    }
  }

  bool hasInteriorIntersection(LineIntersector li, Coordinate p0, Coordinate p1) {
    for (int i = 0; i < li.getIntersectionNum(); i++) {
      Coordinate intPt = li.getIntersection(i);
      if (!(intPt == p0 || intPt == p1)) return true;
    }
    return false;
  }

  void checkEndPtVertexIntersections() {
    for (var ss in segStrings) {
      Array<Coordinate> pts = ss.getCoordinates();
      checkEndPtVertexIntersections2(pts[0], segStrings);
      checkEndPtVertexIntersections2(pts[pts.length - 1], segStrings);
    }
  }

  void checkEndPtVertexIntersections2(Coordinate testPt, List<SegmentString> segStrings) {
    for (var ss in segStrings) {
      Array<Coordinate> pts = ss.getCoordinates();
      for (int j = 1; j < (pts.length - 1); j++) {
        if (pts[j] == testPt) {
          throw "found endpt/interior pt intersection at index $j :pt $testPt";
        }
      }
    }
  }
}
