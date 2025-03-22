import 'quad_edge_triangle.dart';
import 'traversal_visitor.dart';

class EdgeConnectedTriangleTraversal {
  final List<QuadEdgeTriangle> _triQueue = [];

  void init2(QuadEdgeTriangle tri) {
    _triQueue.add(tri);
  }

  void init(List<QuadEdgeTriangle> tris) {
    _triQueue.addAll(tris);
  }

  void visitAll(TraversalVisitor visitor) {
    while (_triQueue.isNotEmpty) {
      final tri = _triQueue.removeAt(0);
      process(tri, visitor);
    }
  }

  void process(QuadEdgeTriangle currTri, TraversalVisitor visitor) {
    currTri.getNeighbours();
    for (int i = 0; i < 3; i++) {
      final neighTri = ((currTri.getEdge(i).sym().data as QuadEdgeTriangle?));
      if (neighTri == null) {
        continue;
      }

      if (visitor.visit(currTri, i, neighTri)) {
        _triQueue.add(neighTri);
      }
    }
  }
}
