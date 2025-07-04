import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

class CoverageBoundarySegmentFinder implements CoordinateSequenceFilter {
  static Set<LineSegment> findBoundarySegments(Array<Geometry> geoms) {
    Set<LineSegment> segs = <LineSegment>{};
    CoverageBoundarySegmentFinder finder = CoverageBoundarySegmentFinder(segs);
    geoms.each((e, i) => e.apply2(finder));
    return segs;
  }

  static bool isBoundarySegment(Set<LineSegment> boundarySegs, CoordinateSequence seq, int i) {
    LineSegment seg = _createSegment(seq, i);
    return boundarySegs.contains(seg);
  }

  final Set<LineSegment> _boundarySegs;

  CoverageBoundarySegmentFinder(this._boundarySegs);

  @override
  void filter(CoordinateSequence seq, int i) {
    if (i >= (seq.size() - 1)) {
      return;
    }

    LineSegment seg = _createSegment(seq, i);
    if (_boundarySegs.contains(seg)) {
      _boundarySegs.remove(seg);
    } else {
      _boundarySegs.add(seg);
    }
  }

  static LineSegment _createSegment(CoordinateSequence seq, int i) {
    LineSegment seg = LineSegment(seq.getCoordinate(i), seq.getCoordinate(i + 1));
    seg.normalize();
    return seg;
  }

  @override
  bool isDone() {
    return false;
  }

  @override
  bool isGeometryChanged() {
    return false;
  }
}
