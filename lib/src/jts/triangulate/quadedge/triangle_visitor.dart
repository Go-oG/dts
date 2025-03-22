 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/triangulate/quadedge/quad_edge.dart';

abstract interface class TriangleVisitor {
  void visit(Array<QuadEdge> triEdges);
}
