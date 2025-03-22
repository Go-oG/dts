import 'quad_edge.dart';
import 'vertex.dart';

abstract interface class QuadEdgeLocator {
  QuadEdge? locate(Vertex v);
}
