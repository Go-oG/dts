import 'package:dts/src/jts/triangulate/quadedge/quad_edge.dart';

abstract interface class TriangleVisitor {
  void visit(List<QuadEdge> triEdges);
}
