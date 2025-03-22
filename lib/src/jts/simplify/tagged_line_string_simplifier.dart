 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

import 'component_jump_checker.dart';
import 'line_segment_index.dart';
import 'tagged_line_segment.dart';
import 'tagged_line_string.dart';

class TaggedLineStringSimplifier {
  LineIntersector li = RobustLineIntersector();

  final LineSegmentIndex _inputIndex;

  final LineSegmentIndex _outputIndex;

  final ComponentJumpChecker _jumpChecker;

  late TaggedLineString _line;

  late Array<Coordinate> _linePts;

  TaggedLineStringSimplifier(this._inputIndex, this._outputIndex, this._jumpChecker);

  void simplify(TaggedLineString line, double distanceTolerance) {
    _line = line;
    _linePts = line.getParentCoordinates();
    simplifySection(0, _linePts.length - 1, 0, distanceTolerance);
    if (line.isRing() && CoordinateArrays.isRing(_linePts)) {
      simplifyRingEndpoint(distanceTolerance);
    }
  }

  void simplifySection(int i, int j, int depth, double distanceTolerance) {
    depth += 1;
    if ((i + 1) == j) {
      LineSegment newSeg = _line.getSegment(i);
      _line.addToResult(newSeg);
      return;
    }
    bool isValidToSimplify = true;
    if (_line.getResultSize() < _line.getMinimumSize()) {
      int worstCaseSize = depth + 1;
      if (worstCaseSize < _line.getMinimumSize()) {
        isValidToSimplify = false;
      }
    }
    Array<double> distance = Array(1);
    int furthestPtIndex = findFurthestPoint(_linePts, i, j, distance);
    if (distance[0] > distanceTolerance) {
      isValidToSimplify = false;
    }
    if (isValidToSimplify) {
      LineSegment flatSeg = LineSegment.empty();
      flatSeg.p0 = _linePts[i];
      flatSeg.p1 = _linePts[j];
      isValidToSimplify = _isTopologyValid(_line, i, j, flatSeg);
    }
    if (isValidToSimplify) {
      LineSegment newSeg = flatten(i, j);
      _line.addToResult(newSeg);
      return;
    }
    simplifySection(i, furthestPtIndex, depth, distanceTolerance);
    simplifySection(furthestPtIndex, j, depth, distanceTolerance);
  }

  void simplifyRingEndpoint(double distanceTolerance) {
    if (_line.getResultSize() > _line.getMinimumSize()) {
      LineSegment firstSeg = _line.getResultSegment(0);
      LineSegment lastSeg = _line.getResultSegment(-1);
      LineSegment simpSeg = LineSegment(lastSeg.p0, firstSeg.p1);
      Coordinate endPt = firstSeg.p0;
      if ((simpSeg.distance(endPt) <= distanceTolerance) && _isTopologyValid2(_line, firstSeg, lastSeg, simpSeg)) {
        _inputIndex.remove(firstSeg);
        _inputIndex.remove(lastSeg);
        _outputIndex.remove(firstSeg);
        _outputIndex.remove(lastSeg);
        LineSegment flatSeg = _line.removeRingEndpoint();
        _outputIndex.add(flatSeg);
      }
    }
  }

  int findFurthestPoint(Array<Coordinate> pts, int i, int j, Array<double> maxDistance) {
    LineSegment seg = LineSegment.empty();
    seg.p0 = pts[i];
    seg.p1 = pts[j];
    double maxDist = -1.0;
    int maxIndex = i;
    for (int k = i + 1; k < j; k++) {
      Coordinate midPt = pts[k];
      double distance = seg.distance(midPt);
      if (distance > maxDist) {
        maxDist = distance;
        maxIndex = k;
      }
    }
    maxDistance[0] = maxDist;
    return maxIndex;
  }

  LineSegment flatten(int start, int end) {
    Coordinate p0 = _linePts[start];
    Coordinate p1 = _linePts[end];
    LineSegment newSeg = LineSegment(p0, p1);
    _outputIndex.add(newSeg);
    remove(_line, start, end);
    return newSeg;
  }

  bool _isTopologyValid(TaggedLineString line, int sectionStart, int sectionEnd, LineSegment flatSeg) {
    if (hasOutputIntersection(flatSeg)) {
      return false;
    }

    if (_hasInputIntersection2(line, sectionStart, sectionEnd, flatSeg)) return false;

    if (_jumpChecker.hasJump(line, sectionStart, sectionEnd, flatSeg)) {
      return false;
    }

    return true;
  }

  bool _isTopologyValid2(TaggedLineString line, LineSegment seg1, LineSegment seg2, LineSegment flatSeg) {
    if (isCollinear(seg1.p0, flatSeg)) {
      return true;
    }

    if (hasOutputIntersection(flatSeg)) {
      return false;
    }

    if (_hasInputIntersection(flatSeg)) {
      return false;
    }

    if (_jumpChecker.hasJump2(line, seg1, seg2, flatSeg)) {
      return false;
    }

    return true;
  }

  bool isCollinear(Coordinate pt, LineSegment seg) {
    return Orientation.collinear == seg.orientationIndex(pt);
  }

  bool hasOutputIntersection(LineSegment flatSeg) {
    List<LineSegment> querySegs = _outputIndex.query(flatSeg);
    for (var querySeg in querySegs) {
      if (hasInvalidIntersection(querySeg, flatSeg)) {
        return true;
      }
    }
    return false;
  }

  bool _hasInputIntersection(LineSegment flatSeg) {
    return _hasInputIntersection2(null, -1, -1, flatSeg);
  }

  bool _hasInputIntersection2(TaggedLineString? line, int excludeStart, int excludeEnd, LineSegment flatSeg) {
    final querySegs = _inputIndex.query(flatSeg);
    for (var i in querySegs) {
      TaggedLineSegment querySeg = i as TaggedLineSegment;
      if (hasInvalidIntersection(querySeg, flatSeg)) {
        if ((line != null) && isInLineSection(line, excludeStart, excludeEnd, querySeg)) {
          continue;
        }

        return true;
      }
    }
    return false;
  }

  static bool isInLineSection(TaggedLineString line, int excludeStart, int excludeEnd, TaggedLineSegment seg) {
    if (seg.getParent() != line.getParent()) {
      return false;
    }

    int segIndex = seg.getIndex();
    if (excludeStart <= excludeEnd) {
      if ((segIndex >= excludeStart) && (segIndex < excludeEnd)) {
        return true;
      }
    } else if ((segIndex >= excludeStart) || (segIndex <= excludeEnd)) {
      return true;
    }
    return false;
  }

  bool hasInvalidIntersection(LineSegment seg0, LineSegment seg1) {
    if (seg0.equalsTopo(seg1)) {
      return true;
    }

    li.computeIntersection2(seg0.p0, seg0.p1, seg1.p0, seg1.p1);
    return li.isInteriorIntersection();
  }

  void remove(TaggedLineString line, int start, int end) {
    for (int i = start; i < end; i++) {
      TaggedLineSegment seg = line.getSegment(i);
      _inputIndex.remove(seg);
    }
  }
}
