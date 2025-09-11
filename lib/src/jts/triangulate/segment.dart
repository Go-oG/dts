import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

class Segment {
  late final LineSegment _ls;

  final Object? data;

  Segment(Coordinate p0, Coordinate p1, [this.data]) {
    _ls = LineSegment(p0, p1);
  }

  Segment.of(double x1, double y1, double z1, double x2, double y2, double z2,
      [Object? data])
      : this(Coordinate(x1, y1, z1), Coordinate(x2, y2, z2), data);

  Coordinate getStart() => _ls.getCoordinate(0);

  Coordinate getEnd() => _ls.getCoordinate(1);

  double getStartX() => _ls.getCoordinate(0).x;

  double getStartY() => _ls.getCoordinate(0).y;

  double getStartZ() => _ls.getCoordinate(0).z;

  double getEndX() => _ls.getCoordinate(1).x;

  double getEndY() => _ls.getCoordinate(1).y;
  double getEndZ() => _ls.getCoordinate(1).z;

  LineSegment getLineSegment() => _ls;

  bool equalsTopo(Segment s) => _ls.equalsTopo(s.getLineSegment());

  Coordinate? intersection(Segment s) => _ls.intersection(s.getLineSegment());

  @override
  String toString() {
    return _ls.toString();
  }
}
