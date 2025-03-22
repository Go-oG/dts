import 'package:dts/src/jts/planargraph/node.dart';

import 'directed_edge.dart';
import 'edge.dart';
import 'node_map.dart';
import 'planar_graph.dart';

class Subgraph {
  PlanarGraph parentGraph;

  final edges = <PGEdge>{};

  List<DirectedEdgePG> dirEdges = [];

  PGNodeMap nodeMap = PGNodeMap();

  Subgraph(this.parentGraph);

  PlanarGraph getParent() {
    return parentGraph;
  }

  void add(PGEdge e) {
    if (edges.contains(e)) {
      return;
    }

    edges.add(e);
    dirEdges.add(e.getDirEdge(0));
    dirEdges.add(e.getDirEdge(1));
    nodeMap.add(e.getDirEdge(0).getFromNode());
    nodeMap.add(e.getDirEdge(1).getFromNode());
  }

  Iterable<DirectedEdgePG> dirEdgeIterator() {
    return dirEdges;
  }

  Iterable<PGEdge> edgeIterator() {
    return edges;
  }

  Iterable<PGNode> nodeIterator() {
    return nodeMap.iterator();
  }

  bool contains(PGEdge e) {
    return edges.contains(e);
  }
}
