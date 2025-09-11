import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/node.dart';

class SegmentIntersector {
  static bool isAdjacentSegments(int i1, int i2) {
    return Math.abs(i1 - i2) == 1;
  }

  bool hasIntersection = false;

  bool _hasProper = false;

  bool _hasProperInterior = false;

  Coordinate? properIntersectionPoint;

  final LineIntersector _li;

  final bool _includeProper;

  final bool _recordIsolated;

  bool isSelfIntersection = false;

  int numIntersections = 0;

  int numTests = 0;

  late Array<List<Node>> _bdyNodes;

  SegmentIntersector(this._li, this._includeProper, this._recordIsolated);

  void setBoundaryNodes(List<Node> bdyNodes0, List<Node> bdyNodes1) {
    _bdyNodes = Array(2);
    _bdyNodes[0] = bdyNodes0;
    _bdyNodes[1] = bdyNodes1;
  }

  bool isDone() {
    return false;
  }

  bool hasProperIntersection() {
    return _hasProper;
  }

  bool hasProperInteriorIntersection() {
    return _hasProperInterior;
  }

  bool isTrivialIntersection(Edge e0, int segIndex0, Edge e1, int segIndex1) {
    if (e0 == e1) {
      if (_li.getIntersectionNum() == 1) {
        if (isAdjacentSegments(segIndex0, segIndex1)) return true;

        if (e0.isClosed()) {
          int maxSegIndex = e0.getNumPoints() - 1;
          if (((segIndex0 == 0) && (segIndex1 == maxSegIndex)) ||
              ((segIndex1 == 0) && (segIndex0 == maxSegIndex))) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void addIntersections(Edge e0, int segIndex0, Edge e1, int segIndex1) {
    if ((e0 == e1) && (segIndex0 == segIndex1)) return;

    numTests++;
    Coordinate p00 = e0.getCoordinate2(segIndex0);
    Coordinate p01 = e0.getCoordinate2(segIndex0 + 1);
    Coordinate p10 = e1.getCoordinate2(segIndex1);
    Coordinate p11 = e1.getCoordinate2(segIndex1 + 1);
    _li.computeIntersection2(p00, p01, p10, p11);
    if (_li.hasIntersection()) {
      if (_recordIsolated) {
        e0.setIsolated(false);
        e1.setIsolated(false);
      }
      numIntersections++;
      if (!isTrivialIntersection(e0, segIndex0, e1, segIndex1)) {
        hasIntersection = true;
        bool isBoundaryPt = isBoundaryPoint(_li, _bdyNodes);
        bool isNotProper = (!_li.isProper) || isBoundaryPt;
        if (_includeProper || isNotProper) {
          e0.addIntersections(_li, segIndex0, 0);
          e1.addIntersections(_li, segIndex1, 1);
        }
        if (_li.isProper) {
          properIntersectionPoint = _li.getIntersection(0).copy();
          _hasProper = true;
          if (!isBoundaryPt) _hasProperInterior = true;
        }
      }
    }
  }

  bool isBoundaryPoint(LineIntersector li, Array<List<Node>>? bdyNodes) {
    if (bdyNodes == null) return false;

    if (isBoundaryPointInternal(li, bdyNodes[0])) return true;

    if (isBoundaryPointInternal(li, bdyNodes[1])) return true;

    return false;
  }

  bool isBoundaryPointInternal(LineIntersector li, List<Node> bdyNodes) {
    for (var node in bdyNodes) {
      Coordinate pt = node.getCoordinate();
      if (li.isIntersection(pt)) return true;
    }
    return false;
  }
}
