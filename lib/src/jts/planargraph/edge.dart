import 'package:d_util/d_util.dart';

import 'directed_edge.dart';
import 'graph_component.dart';
import 'node.dart';

class PGEdge extends GraphComponentPG {
  Array<DirectedEdgePG>? dirEdge;

  PGEdge();

  PGEdge.of(DirectedEdgePG de0, DirectedEdgePG de1) {
    setDirectedEdges(de0, de1);
  }

  void setDirectedEdges(DirectedEdgePG de0, DirectedEdgePG de1) {
    dirEdge = [de0, de1].toArray();
    de0.setEdge(this);
    de1.setEdge(this);
    de0.setSym(de1);
    de1.setSym(de0);
    de0.getFromNode().addOutEdge(de0);
    de1.getFromNode().addOutEdge(de1);
  }

  DirectedEdgePG getDirEdge(int i) {
    return dirEdge![i];
  }

  DirectedEdgePG? getDirEdge2(PGNode fromNode) {
    if (dirEdge![0].getFromNode() == fromNode) {
      return dirEdge![0];
    }

    if (dirEdge![1].getFromNode() == fromNode) {
      return dirEdge![1];
    }

    return null;
  }

  PGNode? getOppositeNode(PGNode node) {
    if (dirEdge![0].getFromNode() == node) return dirEdge![0].getToNode();

    if (dirEdge![1].getFromNode() == node) {
      return dirEdge![1].getToNode();
    }
    return null;
  }

  void remove() {
    dirEdge = null;
  }

  @override
  bool isRemoved() {
    return dirEdge == null;
  }
}
