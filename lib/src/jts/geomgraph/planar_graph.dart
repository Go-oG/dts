import 'dart:core';
import 'dart:math';

import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/quadrant.dart';

import 'edge.dart';
import 'label.dart';
import 'node.dart';
import 'node_factory.dart';
import 'node_map.dart';

class PGPlanarGraph {
  static void linkResultDirectedEdges2(Iterable<Node> nodes) {
    for (var node in nodes) {
      ((node.getEdges() as DirectedEdgeStar)).linkResultDirectedEdges();
    }
  }

  List<Edge> edges = [];

  late NodeMap nodes;

  List<EdgeEnd> edgeEndList = [];

  PGPlanarGraph([NodeFactory? nodeFact]) {
    nodes = NodeMap(nodeFact ?? NodeFactory());
  }

  List<Edge> getEdgeIterator() {
    return edges;
  }

  List<EdgeEnd> getEdgeEnds() {
    return edgeEndList;
  }

  bool isBoundaryNode(int geomIndex, Coordinate coord) {
    Node? node = nodes.find(coord);
    if (node == null) return false;

    Label? label = node.getLabel();
    if ((label != null) && (label.getLocation(geomIndex) == Location.boundary)) {
      return true;
    }

    return false;
  }

  void insertEdge(Edge e) {
    edges.add(e);
  }

  void add(EdgeEnd e) {
    nodes.add(e);
    edgeEndList.add(e);
  }

  Iterable<Node> getNodeIterator() {
    return nodes.iterator();
  }

  Iterable<Node> getNodes() {
    return nodes.values();
  }

  Node addNode2(Node node) {
    return nodes.addNode2(node);
  }

  Node addNode(Coordinate coord) {
    return nodes.addNode(coord);
  }

  Node? find(Coordinate coord) {
    return nodes.find(coord);
  }

  void addEdges(List<Edge> edgesToAdd) {
    for (var e in edgesToAdd) {
      edges.add(e);
      DirectedEdge de1 = DirectedEdge(e, true);
      DirectedEdge de2 = DirectedEdge(e, false);
      de1.setSym(de2);
      de2.setSym(de1);
      add(de1);
      add(de2);
    }
  }

  void linkResultDirectedEdges() {
    for (var node in nodes.values()) {
      ((node.getEdges() as DirectedEdgeStar)).linkResultDirectedEdges();
    }
  }

  void linkAllDirectedEdges() {
    for (var node in nodes.values()) {
      ((node.getEdges() as DirectedEdgeStar)).linkAllDirectedEdges();
    }
  }

  EdgeEnd? findEdgeEnd(Edge e) {
    for (var ee in getEdgeEnds()) {
      if (ee.getEdge() == e) return ee;
    }
    return null;
  }

  Edge? findEdge(Coordinate p0, Coordinate p1) {
    for (var e in edges) {
      final eCoord = e.getCoordinates();
      if (p0 == eCoord[0] && p1 == eCoord[1]) return e;
    }
    return null;
  }

  Edge? findEdgeInSameDirection(Coordinate p0, Coordinate p1) {
    for (var e in edges) {
      final eCoord = e.getCoordinates();
      if (matchInSameDirection(p0, p1, eCoord[0], eCoord[1])) return e;
      if (matchInSameDirection(p0, p1, eCoord[eCoord.length - 1], eCoord[eCoord.length - 2])) {
        return e;
      }
    }
    return null;
  }

  bool matchInSameDirection(Coordinate p0, Coordinate p1, Coordinate ep0, Coordinate ep1) {
    if (p0 != ep0) return false;

    if ((Orientation.index(p0, p1, ep1) == Orientation.collinear) &&
        (Quadrant.quadrant2(p0, p1) == Quadrant.quadrant2(ep0, ep1))) {
      return true;
    }

    return false;
  }
}
