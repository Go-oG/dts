import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

class Segment {
  late LineSegment _ls;

  Object? data;

  Segment(Coordinate p0, Coordinate p1, [this.data]) {
    _ls = LineSegment(p0, p1);
  }

  Segment.of(double x1, double y1, double z1, double x2, double y2, double z2)
    : this(Coordinate(x1, y1, z1), Coordinate(x2, y2, z2));

  Segment.of2(double x1, double y1, double z1, double x2, double y2, double z2, Object? data)
    : this(Coordinate(x1, y1, z1), Coordinate(x2, y2, z2), data);

  Coordinate getStart() {
    return _ls.getCoordinate(0);
  }

  Coordinate getEnd() {
    return _ls.getCoordinate(1);
  }

  double getStartX() {
    Coordinate p = _ls.getCoordinate(0);
    return p.x;
  }

  double getStartY() {
    Coordinate p = _ls.getCoordinate(0);
    return p.y;
  }

  double getStartZ() {
    Coordinate p = _ls.getCoordinate(0);
    return p.getZ();
  }

  double getEndX() {
    Coordinate p = _ls.getCoordinate(1);
    return p.x;
  }

  double getEndY() {
    Coordinate p = _ls.getCoordinate(1);
    return p.y;
  }

  double getEndZ() {
    Coordinate p = _ls.getCoordinate(1);
    return p.getZ();
  }

  LineSegment getLineSegment() {
    return _ls;
  }

  bool equalsTopo(Segment s) {
    return _ls.equalsTopo(s.getLineSegment());
  }

  Coordinate? intersection(Segment s) {
    return _ls.intersection(s.getLineSegment());
  }

  @override
  String toString() {
    return _ls.toString();
  }
}
