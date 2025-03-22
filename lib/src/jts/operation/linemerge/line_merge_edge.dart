import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/planargraph/edge.dart';

class LineMergeEdge extends PGEdge {
  LineString line;
  LineMergeEdge(this.line);
  LineString getLine() {
    return line;
  }

}
