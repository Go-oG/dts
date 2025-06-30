import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

class TaggedLineSegment extends LineSegment {
  Geometry? parent;
  int index;

  TaggedLineSegment(super.p0, super.p1, this.parent, this.index);

  TaggedLineSegment.of(Coordinate p0, Coordinate p1) : this(p0, p1, null, -1);

  Geometry? getParent() {
    return parent;
  }

  int getIndex() {
    return index;
  }
}
