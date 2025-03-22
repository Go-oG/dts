 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

import 'tri.dart';
import 'tri_edge.dart';

class TriangulationBuilder {
  static void build<T extends Tri>(List<T> triList) {
    TriangulationBuilder(triList);
  }

  final Map<TriEdge, Tri> _triMap = {};

  TriangulationBuilder(List<Tri> triList) {
    for (Tri tri in triList) {
      add(tri);
    }
  }

  Tri? find(Coordinate p0, Coordinate p1) {
    TriEdge e = TriEdge(p0, p1);
    return _triMap.get(e);
  }

  void add(Tri tri) {
    Coordinate p0 = tri.getCoordinate(0);
    Coordinate p1 = tri.getCoordinate(1);
    Coordinate p2 = tri.getCoordinate(2);
    Tri? n0 = find(p0, p1);
    Tri? n1 = find(p1, p2);
    Tri? n2 = find(p2, p0);
    tri.setAdjacent(n0, n1, n2);
    addAdjacent(tri, n0, p0, p1);
    addAdjacent(tri, n1, p1, p2);
    addAdjacent(tri, n2, p2, p0);
  }

  void addAdjacent(Tri tri, Tri? adj, Coordinate p0, Coordinate p1) {
    if (adj == null) {
      _triMap.put(TriEdge(p0, p1), tri);
      return;
    }
    adj.setAdjacent2(p1, tri);
  }
}
