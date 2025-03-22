import 'package:dts/src/jts/geom/line_segment.dart';

class LocateFailureException {
  static String msgWithSpatial(String msg, LineSegment? seg) {
    if (seg != null) return "$msg [ $seg ]";

    return msg;
  }

  String msg = "";
  LineSegment? _seg;

  LocateFailureException(this.msg, [LineSegment? seg]) {
    if (seg != null) {
      _seg = LineSegment.of(seg);
    }
  }

  LocateFailureException.of(LineSegment seg) {
    msg =
        "Locate failed to converge (at edge: $seg).  Possible causes include invalid Subdivision topology or very close sites";

    _seg = LineSegment.of(seg);
  }

  LineSegment? getSegment() {
    return _seg;
  }
}
