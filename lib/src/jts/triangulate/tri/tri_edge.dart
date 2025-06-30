import 'package:dts/src/jts/geom/coordinate.dart';

class TriEdge {
  Coordinate p0;

  Coordinate p1;

  TriEdge(this.p0, this.p1) {
    normalize();
  }

  void normalize() {
    if (p0.compareTo(p1) < 0) {
      Coordinate tmp = p0;
      p0 = p1;
      p1 = tmp;
    }
  }

  @override
  int get hashCode {
    int result = 17;
    result = (37 * result) + Coordinate.hashCodeS(p0.x);
    result = (37 * result) + Coordinate.hashCodeS(p1.x);
    result = (37 * result) + Coordinate.hashCodeS(p0.y);
    result = (37 * result) + Coordinate.hashCodeS(p1.y);
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is! TriEdge) return false;
    if (p0 == other.p0 && p1 == other.p1) return true;
    return false;
  }
}
