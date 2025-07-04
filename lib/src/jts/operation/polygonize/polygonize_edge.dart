import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/planargraph/edge.dart';

class PolygonizeEdge extends PGEdge {
  LineString line;
  PolygonizeEdge(this.line);
  LineString getLine()=>line;
}
