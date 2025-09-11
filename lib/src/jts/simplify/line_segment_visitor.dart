import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/index/item_visitor.dart';

class LineSegmentVisitor implements ItemVisitor<LineSegment> {
  final LineSegment _querySeg;

  final List<LineSegment> _items = [];

  LineSegmentVisitor(this._querySeg);

  @override
  void visitItem(LineSegment seg) {
    if (Envelope.intersects4(seg.p0, seg.p1, _querySeg.p0, _querySeg.p1)) {
      _items.add(seg);
    }
  }

  List<LineSegment> getItems() {
    return _items;
  }
}
