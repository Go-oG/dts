import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/planargraph/graph_component.dart';
import 'package:dts/src/jts/planargraph/node.dart';
import 'package:dts/src/jts/planargraph/planar_graph.dart';
import 'package:dts/src/jts/planargraph/subgraph.dart';

class ConnectedSubgraphFinder {
  final PlanarGraph _graph;

  ConnectedSubgraphFinder(this._graph);

  List<Subgraph> getConnectedSubGraphs() {
    List<Subgraph> subGraphs = [];
    GraphComponentPG.setVisited2(_graph.nodeIterator(), false);
    for (var e in _graph.edgeIterator()) {
      PGNode node = e.getDirEdge(0).getFromNode();
      if (!node.isVisited) {
        subGraphs.add(findSubgraph(node));
      }
    }

    return subGraphs;
  }

  Subgraph findSubgraph(PGNode node) {
    Subgraph subgraph = Subgraph(_graph);
    addReachable(node, subgraph);
    return subgraph;
  }

  void addReachable(PGNode startNode, Subgraph subgraph) {
    Stack<PGNode> nodeStack = Stack();
    nodeStack.add(startNode);
    while (nodeStack.isNotEmpty) {
      PGNode node = nodeStack.pop();
      addEdges(node, nodeStack, subgraph);
    }
  }

  void addEdges(PGNode node, Stack nodeStack, Subgraph subgraph) {
    node.isVisited = true;
    for (var de in node.getOutEdges().iterator()) {
      subgraph.add(de.getEdge()!);
      PGNode toNode = de.getToNode();
      if (!toNode.isVisited) {
        nodeStack.push(toNode);
      }
    }
  }
}
