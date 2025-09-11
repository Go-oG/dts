import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/index/quadtree/quad_tree.dart';

import 'line_segment_visitor.dart';
import 'tagged_line_segment.dart';
import 'tagged_line_string.dart';

class LineSegmentIndex {
  final Quadtree _index = Quadtree();

  void add2(TaggedLineString line) {
    final segs = line.getSegments();
    for (int i = 0; i < segs.length; i++) {
      TaggedLineSegment seg = segs[i];
      add(seg);
    }
  }

  void add(LineSegment seg) {
    _index.insert(Envelope.of(seg.p0, seg.p1), seg);
  }

  void remove(LineSegment seg) {
    _index.remove(Envelope.of(seg.p0, seg.p1), seg);
  }

  List<LineSegment> query(LineSegment querySeg) {
    Envelope env = Envelope.of(querySeg.p0, querySeg.p1);
    final visitor = LineSegmentVisitor(querySeg);
    _index.each(env, visitor);
    return visitor.getItems();
  }
}
