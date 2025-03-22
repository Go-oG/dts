import 'quad_edge.dart';

class QuadEdgeUtil {
  static List<QuadEdge> findEdgesIncidentOnOrigin(QuadEdge start) {
    List<QuadEdge> incEdge = [];
    QuadEdge qe = start;
    do {
      incEdge.add(qe);
      qe = qe.oNext();
    } while (qe != start);
    return incEdge;
  }
}
