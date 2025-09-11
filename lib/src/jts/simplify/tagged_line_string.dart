import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';

import 'tagged_line_segment.dart';

class TaggedLineString {
  final LineString _parentLine;

  late List<TaggedLineSegment> _segs;

  final List<LineSegment> _resultSegs = [];

  final int _minimumSize;

  final bool _isRing;

  TaggedLineString(this._parentLine, this._minimumSize, this._isRing) {
    init();
  }

  bool isRing() {
    return _isRing;
  }

  int getMinimumSize() {
    return _minimumSize;
  }

  LineString getParent() {
    return _parentLine;
  }

  List<Coordinate> getParentCoordinates() => _parentLine.getCoordinates();

  List<Coordinate> getResultCoordinates() => extractCoordinates(_resultSegs);

  Coordinate getCoordinate(int i) => _parentLine.getCoordinateN(i);

  int size() => _parentLine.getNumPoints();

  Coordinate getComponentPoint() {
    if (_resultSegs.size > 0) {
      return _resultSegs.first.p0;
    }

    return getParentCoordinates()[1];
  }

  int getResultSize() {
    int resultSegsSize = _resultSegs.size;
    return resultSegsSize == 0 ? 0 : resultSegsSize + 1;
  }

  TaggedLineSegment getSegment(int i) => _segs[i];

  LineSegment getResultSegment(int i) {
    int index = i;
    if (i < 0) {
      index = _resultSegs.size + i;
    }
    return _resultSegs.get(index);
  }

  void init() {
    final pts = _parentLine.getCoordinates();
    _segs = Array()[pts.length - 1];
    for (int i = 0; i < (pts.length - 1); i++) {
      final seg = TaggedLineSegment(pts[i], pts[i + 1], _parentLine, i);
      _segs[i] = seg;
    }
  }

  List<TaggedLineSegment> getSegments() => _segs;

  void addToResult(LineSegment seg) => _resultSegs.add(seg);

  LineString asLineString() {
    return _parentLine.factory
        .createLineString2(extractCoordinates(_resultSegs));
  }

  LinearRing asLinearRing() {
    return _parentLine.factory
        .createLinearRings(extractCoordinates(_resultSegs));
  }

  static List<Coordinate> extractCoordinates(List<LineSegment> segs) {
    List<Coordinate> pts = [];
    late LineSegment seg;
    for (int i = 0; i < segs.size; i++) {
      seg = segs.get(i);
      pts.add(seg.p0);
    }
    pts.add(seg.p1);
    return pts;
  }

  LineSegment removeRingEndpoint() {
    LineSegment firstSeg = _resultSegs.first;
    LineSegment lastSeg = _resultSegs.last;
    firstSeg.p0 = lastSeg.p0;
    _resultSegs.removeLast();
    return firstSeg;
  }
}
