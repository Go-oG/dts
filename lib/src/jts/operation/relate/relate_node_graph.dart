import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/geometry_graph.dart';
import 'package:dts/src/jts/geomgraph/node.dart';
import 'package:dts/src/jts/geomgraph/node_map.dart';

import 'edge_end_builder.dart';
import 'relate_node.dart';
import 'relate_node_factory.dart';

class RelateNodeGraph {
  final nodes = NodeMap(RelateNodeFactory());

  Iterable<Node> getNodeIterator() {
    return nodes.iterator();
  }

  void build(GeometryGraph geomGraph) {
    computeIntersectionNodes(geomGraph, 0);
    copyNodesAndLabels(geomGraph, 0);
    final eeBuilder = EdgeEndBuilder();
    final eeList = eeBuilder.computeEdgeEnds2(geomGraph.getEdgeIterator());
    insertEdgeEnds(eeList);
  }

  void computeIntersectionNodes(GeometryGraph geomGraph, int argIndex) {
    for (var e in geomGraph.getEdgeIterator()) {
      int eLoc = e.getLabel()!.getLocation(argIndex);
      for (var ei in e.getEdgeIntersectionList().iterator()) {
        RelateNode n = (nodes.addNode(ei.coord) as RelateNode);
        if (eLoc == Location.boundary) {
          n.setLabelBoundary(argIndex);
        } else if (n.getLabel()!.isNull(argIndex)) {
          n.setLabel2(argIndex, Location.interior);
        }
      }
    }
  }

  void copyNodesAndLabels(GeometryGraph geomGraph, int argIndex) {
    for (var graphNode in geomGraph.getNodeIterator()) {
      Node newNode = nodes.addNode(graphNode.getCoordinate());
      newNode.setLabel2(argIndex, graphNode.getLabel()!.getLocation(argIndex));
    }
  }

  void insertEdgeEnds(List<EdgeEnd> ee) {
    for (var e in ee) {
      nodes.add(e);
    }
  }
}
