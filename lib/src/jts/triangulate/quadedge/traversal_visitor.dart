import 'quad_edge_triangle.dart';

abstract interface class TraversalVisitor {
  bool visit(QuadEdgeTriangle currTri, int edgeIndex, QuadEdgeTriangle neighbTri);
}
