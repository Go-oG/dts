import 'dart:collection';

 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/location.dart';

import 'edge.dart';
import 'node.dart';
import 'node_factory.dart';

class NodeMap {
  SplayTreeMap<Coordinate, Node> nodeMap = SplayTreeMap();

  NodeFactory nodeFact;

  NodeMap(this.nodeFact);

  Node addNode(Coordinate coord) {
    Node? node = nodeMap[coord];
    if (node == null) {
      node = nodeFact.createNode(coord);
      nodeMap[coord] = node;
    }
    return node;
  }

  Node addNode2(Node n) {
    Node? node = nodeMap.get(n.getCoordinate());
    if (node == null) {
      nodeMap.put(n.getCoordinate(), n);
      return n;
    }
    node.mergeLabel2(n);
    return node;
  }

  void add(EdgeEnd e) {
    Coordinate p = e.getCoordinate();
    Node n = addNode(p);
    n.add(e);
  }

  Node? find(Coordinate coord) {
    return nodeMap.get(coord);
  }

  Iterable<Node> iterator() {
    return nodeMap.values;
  }

  Iterable<Node> values() {
    return nodeMap.values;
  }

  List<Node> getBoundaryNodes(int geomIndex) {
    List<Node> bdyNodes = [];
    for (var node in nodeMap.values) {
      if (node.getLabel()!.getLocation(geomIndex) == Location.boundary) bdyNodes.add(node);
    }
    return bdyNodes;
  }
}
