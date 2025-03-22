import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/geom/intersection_matrix.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/geometry_graph.dart';
import 'package:dts/src/jts/geomgraph/label.dart';

class EdgeEndBundle extends EdgeEnd {
  final List<EdgeEnd> _edgeEnds = [];

  EdgeEndBundle.of(BoundaryNodeRule? boundaryNodeRule, EdgeEnd e)
    : super.of2(e.getEdge(), e.getCoordinate(), e.getDirectedCoordinate(), Label(e.getLabel()!)) {
    insert(e);
  }

  EdgeEndBundle(EdgeEnd e) : this.of(null, e);

  List<EdgeEnd> iterator() {
    return _edgeEnds;
  }

  List<EdgeEnd> getEdgeEnds() {
    return _edgeEnds;
  }

  void insert(EdgeEnd e) {
    _edgeEnds.add(e);
  }

  @override
  void computeLabel(BoundaryNodeRule boundaryNodeRule) {
    bool isArea = false;
    for (var e in iterator()) {
      if (e.getLabel()!.isArea()) isArea = true;
    }
    if (isArea) {
      label = Label.of3(Location.none, Location.none, Location.none);
    } else {
      label = Label.of(Location.none);
    }

    for (int i = 0; i < 2; i++) {
      computeLabelOn(i, boundaryNodeRule);
      if (isArea) computeLabelSides(i);
    }
  }

  void computeLabelOn(int geomIndex, BoundaryNodeRule boundaryNodeRule) {
    int boundaryCount = 0;
    bool foundInterior = false;
    for (var e in iterator()) {
      int loc = e.getLabel()!.getLocation(geomIndex);
      if (loc == Location.boundary) boundaryCount++;

      if (loc == Location.interior) foundInterior = true;
    }
    int loc = Location.none;
    if (foundInterior) loc = Location.interior;

    if (boundaryCount > 0) {
      loc = GeometryGraph.determineBoundary(boundaryNodeRule, boundaryCount);
    }
    label!.setLocation(geomIndex, loc);
  }

  void computeLabelSides(int geomIndex) {
    computeLabelSide(geomIndex, Position.left);
    computeLabelSide(geomIndex, Position.right);
  }

  void computeLabelSide(int geomIndex, int side) {
    for (var e in iterator()) {
      if (e.getLabel()!.isArea()) {
        int loc = e.getLabel()!.getLocation2(geomIndex, side);
        if (loc == Location.interior) {
          label!.setLocation2(geomIndex, side, Location.interior);
          return;
        } else if (loc == Location.exterior) {
          label!.setLocation2(geomIndex, side, Location.exterior);
        }
      }
    }
  }

  void updateIM(IntersectionMatrix im) {
    Edge.updateIMS(label!, im);
  }
}
