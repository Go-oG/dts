import 'package:d_util/d_util.dart' show Stack;
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';
import 'package:dts/src/jts/geomgraph/node.dart';

import '../../geomgraph/edge.dart';
import 'rightmost_edge_finder.dart';

class BufferSubgraph implements Comparable<BufferSubgraph> {
  final _finder = RightmostEdgeFinder();
  final List<DirectedEdge> _dirEdgeList = [];
  final List<Node> _nodes = [];
  Coordinate? _rightMostCoord;
  Envelope? env;

  List<DirectedEdge> getDirectedEdges() {
    return _dirEdgeList;
  }

  List<Node> getNodes() {
    return _nodes;
  }

  Envelope getEnvelope() {
    if (env == null) {
      Envelope edgeEnv = Envelope();
      for (var dirEdge in _dirEdgeList) {
        List<Coordinate> pts = dirEdge.getEdge().getCoordinates();
        for (int i = 0; i < (pts.length - 1); i++) {
          edgeEnv.expandToIncludeCoordinate(pts[i]);
        }
      }
      env = edgeEnv;
    }
    return env!;
  }

  Coordinate? getRightmostCoordinate() {
    return _rightMostCoord;
  }

  void create(Node node) {
    addReachable(node);
    _finder.findEdge(_dirEdgeList);
    _rightMostCoord = _finder.getCoordinate();
  }

  void addReachable(Node startNode) {
    Stack<Node> nodeStack = Stack();
    nodeStack.add(startNode);
    while (nodeStack.isNotEmpty) {
      Node node = nodeStack.pop();
      add(node, nodeStack);
    }
  }

  void add(Node node, Stack nodeStack) {
    node.isVisited = true;
    _nodes.add(node);
    for (var i in (node.getEdges() as DirectedEdgeStar).iterator()) {
      DirectedEdge de = i as DirectedEdge;
      _dirEdgeList.add(de);
      DirectedEdge sym = de.getSym();
      Node symNode = sym.getNode();
      if (!symNode.isVisited) nodeStack.push(symNode);
    }
  }

  void clearVisitedEdges() {
    for (var de in _dirEdgeList) {
      de.setVisited(false);
    }
  }

  void computeDepth(int outsideDepth) {
    clearVisitedEdges();
    DirectedEdge de = _finder.getEdge()!;
    de.setEdgeDepths(Position.right, outsideDepth);
    copySymDepths(de);
    computeDepths2(de);
  }

  void computeDepths2(DirectedEdge startEdge) {
    final nodesVisited = <Node>{};
    List<Node> nodeQueue = [];
    Node startNode = startEdge.getNode();
    nodeQueue.add(startNode);
    nodesVisited.add(startNode);
    startEdge.setVisited(true);
    while (nodeQueue.isNotEmpty) {
      Node n = nodeQueue.removeAt(0);
      nodesVisited.add(n);
      computeNodeDepth(n);
      for (var i in (n.getEdges() as DirectedEdgeStar).iterator()) {
        DirectedEdge de = i as DirectedEdge;
        DirectedEdge sym = de.getSym();
        if (sym.isVisited()) continue;

        Node adjNode = sym.getNode();
        if (!nodesVisited.contains(adjNode)) {
          nodeQueue.add(adjNode);
          nodesVisited.add(adjNode);
        }
      }
    }
  }

  void computeNodeDepth(Node n) {
    DirectedEdge? startEdge;
    for (var i in ((n.getEdges() as DirectedEdgeStar)).iterator()) {
      DirectedEdge de = i as DirectedEdge;
      if (de.isVisited() || de.getSym().isVisited()) {
        startEdge = de;
        break;
      }
    }
    if (startEdge == null) {
      throw TopologyException(
          "unable to find edge to compute depths at ${n.getCoordinate()}");
    }

    ((n.getEdges() as DirectedEdgeStar)).computeDepths(startEdge);
    for (var i in ((n.getEdges() as DirectedEdgeStar)).iterator()) {
      DirectedEdge de = i as DirectedEdge;
      de.setVisited(true);
      copySymDepths(de);
    }
  }

  void copySymDepths(DirectedEdge de) {
    DirectedEdge sym = de.getSym();
    sym.setDepth(Position.left, de.getDepth(Position.right));
    sym.setDepth(Position.right, de.getDepth(Position.left));
  }

  void findResultEdges() {
    for (var de in _dirEdgeList) {
      if (((de.getDepth(Position.right) >= 1) &&
              (de.getDepth(Position.left) <= 0)) &&
          (!de.isInteriorAreaEdge())) {
        de.setInResult(true);
      }
    }
  }

  @override
  int compareTo(BufferSubgraph graph) {
    if (_rightMostCoord!.x < graph._rightMostCoord!.x) {
      return -1;
    }
    if (_rightMostCoord!.x > graph._rightMostCoord!.x) {
      return 1;
    }
    return 0;
  }
}
