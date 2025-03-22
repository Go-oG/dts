import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/intersection_matrix.dart';
import 'package:dts/src/jts/geom/location.dart';

import 'edge.dart';
import 'graph_component.dart';
import 'label.dart';

class Node extends GraphComponent {
  Coordinate coord;

  EdgeEndStar? edges;

  Node(this.coord, this.edges) {
    label = Label.of2(0, Location.none);
  }

  @override
  Coordinate getCoordinate() {
    return coord;
  }

  EdgeEndStar? getEdges() {
    return edges;
  }

  bool isIncidentEdgeInResult() {
    for (var de in edges!.getEdges()) {
      if (de.getEdge().isInResult) {
        return true;
      }
    }

    return false;
  }

  @override
  bool isIsolated() {
    return label!.getGeometryCount() == 1;
  }

  @override
  void computeIM(IntersectionMatrix im) {}

  void add(EdgeEnd e) {
    edges?.insert(e);
    e.setNode(this);
  }

  void mergeLabel2(Node n) {
    mergeLabel(n.label!);
  }

  void mergeLabel(Label label2) {
    for (int i = 0; i < 2; i++) {
      int loc = computeMergedLocation(label2, i);
      int thisLoc = label!.getLocation(i);
      if (thisLoc == Location.none) label!.setLocation(i, loc);
    }
  }

  void setLabel2(int argIndex, int onLocation) {
    if (label == null) {
      label = Label.of2(argIndex, onLocation);
    } else {
      label!.setLocation(argIndex, onLocation);
    }
  }

  void setLabelBoundary(int argIndex) {
    if (label == null) return;

    int loc = Location.none;
    if (label != null) loc = label!.getLocation(argIndex);

    int newLoc;
    switch (loc) {
      case Location.boundary:
        newLoc = Location.interior;
        break;
      case Location.interior:
        newLoc = Location.boundary;
        break;
      default:
        newLoc = Location.boundary;
        break;
    }
    label!.setLocation(argIndex, newLoc);
  }

  int computeMergedLocation(Label label2, int eltIndex) {
    int loc = Location.none;
    loc = label!.getLocation(eltIndex);
    if (!label2.isNull(eltIndex)) {
      int nLoc = label2.getLocation(eltIndex);
      if (loc != Location.boundary) loc = nLoc;
    }
    return loc;
  }
}
