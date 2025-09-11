import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/planargraph/directed_edge.dart';
import 'package:dts/src/jts/planargraph/edge.dart';
import 'package:dts/src/jts/planargraph/node.dart';
import 'package:dts/src/jts/planargraph/planar_graph.dart';

import 'line_merge_directed_edge.dart';
import 'line_merge_edge.dart';

class LineMergeGraph extends PlanarGraph {
  void addEdge(LineString lineString) {
    if (lineString.isEmpty()) {
      return;
    }
    final coordinates =
        CoordinateArrays.removeRepeatedPoints(lineString.getCoordinates());
    if (coordinates.length <= 1) {
      return;
    }

    Coordinate startCoordinate = coordinates[0];
    Coordinate endCoordinate = coordinates[coordinates.length - 1];
    PGNode startNode = getNode(startCoordinate);
    PGNode endNode = getNode(endCoordinate);
    DirectedEdgePG directedEdge0 =
        LineMergeDirectedEdge(startNode, endNode, coordinates[1], true);
    DirectedEdgePG directedEdge1 = LineMergeDirectedEdge(
      endNode,
      startNode,
      coordinates[coordinates.length - 2],
      false,
    );
    PGEdge edge = LineMergeEdge(lineString);
    edge.setDirectedEdges(directedEdge0, directedEdge1);
    add(edge);
  }

  PGNode getNode(Coordinate coordinate) {
    PGNode? node = findNode(coordinate);
    if (node == null) {
      node = PGNode(coordinate);
      add2(node);
    }
    return node;
  }
}
