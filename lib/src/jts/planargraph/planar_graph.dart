import '../geom/coordinate.dart';
import 'directed_edge.dart';
import 'edge.dart';
import 'node.dart';
import 'node_map.dart';

abstract class PlanarGraph {
  Set<PGEdge> edges = <PGEdge>{};

  Set<DirectedEdgePG> dirEdges = <DirectedEdgePG>{};

  PGNodeMap nodeMap = PGNodeMap();

  PGNode? findNode(Coordinate pt) {
    return nodeMap.find(pt);
  }

  void add2(PGNode node) {
    nodeMap.add(node);
  }

  void add(PGEdge edge) {
    edges.add(edge);
    add3(edge.getDirEdge(0));
    add3(edge.getDirEdge(1));
  }

  void add3(DirectedEdgePG dirEdge) {
    dirEdges.add(dirEdge);
  }

  Iterable<PGNode> nodeIterator() {
    return nodeMap.iterator();
  }

  bool contains(PGEdge e) {
    return edges.contains(e);
  }

  bool contains2(DirectedEdgePG de) {
    return dirEdges.contains(de);
  }

  List<PGNode> getNodes() {
    return nodeMap.values();
  }

  Iterable<DirectedEdgePG> dirEdgeIterator() {
    return dirEdges;
  }

  Iterable<PGEdge> edgeIterator() {
    return edges;
  }

  Set<PGEdge> getEdges() {
    return edges;
  }

  void remove(PGEdge edge) {
    remove2(edge.getDirEdge(0));
    remove2(edge.getDirEdge(1));
    edges.remove(edge);
    edge.remove();
  }

  void remove2(DirectedEdgePG de) {
    DirectedEdgePG? sym = de.getSym();
    if (sym != null) {
      sym.sym = null;
    }

    de.getFromNode().remove2(de);
    de.remove();
    dirEdges.remove(de);
  }

  void remove3(PGNode node) {
    final outEdges = node.getOutEdges().getEdges();
    for (Iterator i = outEdges.iterator; i.moveNext();) {
      DirectedEdgePG de = i as DirectedEdgePG;
      DirectedEdgePG? sym = de.getSym();
      if (sym != null) {
        remove2(sym);
      }

      dirEdges.remove(de);
      PGEdge? edge = de.getEdge();
      if (edge != null) {
        edges.remove(edge);
      }
    }
    nodeMap.remove(node.getCoordinate());
    node.remove();
  }

  List<PGNode> findNodesOfDegree(int degree) {
    List<PGNode> nodesFound = [];
    for (var node in nodeIterator()) {
      if (node.getDegree() == degree) {
        nodesFound.add(node);
      }
    }
    return nodesFound;
  }
}
