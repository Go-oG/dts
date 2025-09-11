import 'package:dts/src/jts/geom/coordinate.dart';

import 'directed_edge_star.dart';
import 'edge.dart';
import 'directed_edge.dart';
import 'graph_component.dart';

class PGNode extends GraphComponentPG {
  static List<PGEdge> getEdgesBetween(PGNode node0, PGNode node1) {
    final edges0 = DirectedEdgePG.toEdges(node0.getOutEdges().getEdges());
    Set<PGEdge> commonEdges = Set.from(edges0);
    List edges1 = DirectedEdgePG.toEdges(node1.getOutEdges().getEdges());
    commonEdges.retainAll(edges1);
    return commonEdges.toList().cast();
  }

  Coordinate? pt;

  late DirectedEdgeStarPG deStar;

  PGNode(this.pt, [DirectedEdgeStarPG? deStar]) {
    this.deStar = deStar ?? DirectedEdgeStarPG();
  }

  Coordinate? getCoordinate() {
    return pt;
  }

  void addOutEdge(DirectedEdgePG de) {
    deStar.add(de);
  }

  DirectedEdgeStarPG getOutEdges() {
    return deStar;
  }

  int getDegree() {
    return deStar.getDegree();
  }

  int getIndex(PGEdge edge) {
    return deStar.getIndex2(edge);
  }

  void remove2(DirectedEdgePG de) {
    deStar.remove(de);
  }

  void remove() {
    pt = null;
  }

  @override
  bool isRemoved() {
    return pt == null;
  }
}
