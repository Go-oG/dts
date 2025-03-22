import 'quad_edge.dart';
import 'quad_edge_locator.dart';
import 'quad_edge_subdivision.dart';
import 'vertex.dart';

class LastFoundQuadEdgeLocator implements QuadEdgeLocator {
  final QuadEdgeSubdivision _subdiv;

  late QuadEdge _lastEdge;

  LastFoundQuadEdgeLocator(this._subdiv) {
    init();
  }

  void init() {
    _lastEdge = findEdge();
  }

  QuadEdge findEdge() {
    List<QuadEdge> edges = _subdiv.getEdges();
    return edges.first;
  }

  @override
  QuadEdge locate(Vertex v) {
    if (!_lastEdge.isLive()) {
      init();
    }
    QuadEdge e = _subdiv.locateFromEdge(v, _lastEdge);
    _lastEdge = e;
    return e;
  }
}
