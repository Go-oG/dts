import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/quadrant.dart';

import 'edge.dart';
import 'graph_component.dart';
import 'node.dart';

class DirectedEdgePG extends GraphComponentPG
    implements Comparable<DirectedEdgePG> {
  static List<PGEdge?> toEdges(List<DirectedEdgePG> dirEdges) {
    List<PGEdge?> edges = [];
    for (var i in dirEdges) {
      edges.add(i.parentEdge);
    }
    return edges;
  }

  PGEdge? parentEdge;

  PGNode from;

  PGNode to;

  late Coordinate p0;

  Coordinate p1;

  DirectedEdgePG? sym;

  bool edgeDirection;

  int quadrant = 0;

  double angle = 0;

  DirectedEdgePG(this.from, this.to, this.p1, this.edgeDirection) {
    p0 = from.getCoordinate()!;
    double dx = p1.x - p0.x;
    double dy = p1.y - p0.y;
    quadrant = Quadrant.quadrant(dx, dy);
    angle = Math.atan2(dy, dx);
  }

  PGEdge? getEdge() {
    return parentEdge;
  }

  void setEdge(PGEdge parentEdge) {
    this.parentEdge = parentEdge;
  }

  int getQuadrant() {
    return quadrant;
  }

  Coordinate getDirectionPt() {
    return p1;
  }

  bool getEdgeDirection() {
    return edgeDirection;
  }

  PGNode getFromNode() {
    return from;
  }

  PGNode getToNode() {
    return to;
  }

  Coordinate? getCoordinate() {
    return from.getCoordinate();
  }

  double getAngle() {
    return angle;
  }

  DirectedEdgePG? getSym() {
    return sym;
  }

  void setSym(DirectedEdgePG sym) {
    this.sym = sym;
  }

  void remove() {
    sym = null;
    parentEdge = null;
  }

  @override
  bool isRemoved() {
    return parentEdge == null;
  }

  @override
  int compareTo(DirectedEdgePG obj) {
    return compareDirection(obj);
  }

  int compareDirection(DirectedEdgePG e) {
    if (quadrant > e.quadrant) {
      return 1;
    }

    if (quadrant < e.quadrant) {
      return -1;
    }

    return Orientation.index(e.p0, e.p1, p1);
  }
}
