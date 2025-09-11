import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';

import 'line_merge_directed_edge.dart';
import 'line_merge_edge.dart';

class EdgeString {
  GeometryFactory factory;

  final List<LineMergeDirectedEdge> _directedEdges = [];

  List<Coordinate>? _coordinates;

  EdgeString(this.factory);

  void add(LineMergeDirectedEdge directedEdge) {
    _directedEdges.add(directedEdge);
  }

  List<Coordinate> getCoordinates() {
    if (_coordinates == null) {
      int forwardDirectedEdges = 0;
      int reverseDirectedEdges = 0;
      CoordinateList coordinateList = CoordinateList();
      for (var directedEdge in _directedEdges) {
        if (directedEdge.getEdgeDirection()) {
          forwardDirectedEdges++;
        } else {
          reverseDirectedEdges++;
        }
        coordinateList.add4(
          (directedEdge.getEdge() as LineMergeEdge).getLine().getCoordinates(),
          false,
          directedEdge.getEdgeDirection(),
        );
      }
      _coordinates = coordinateList.toCoordinateList();
      if (reverseDirectedEdges > forwardDirectedEdges) {
        CoordinateArrays.reverse(_coordinates!);
      }
    }
    return _coordinates!;
  }

  LineString toLineString() {
    return factory.createLineString2(getCoordinates());
  }
}
