 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/line_string.dart';

class LinearBoundary {
  Map<Coordinate, int> _vertexDegree = {};

  late bool _hasBoundary;

  final BoundaryNodeRule _boundaryNodeRule;

  LinearBoundary(List<LineString> lines, this._boundaryNodeRule) {
    _vertexDegree = computeBoundaryPoints(lines);
    _hasBoundary = checkBoundary(_vertexDegree);
  }

  bool checkBoundary(Map<Coordinate, int> vertexDegree) {
    for (int degree in vertexDegree.values) {
      if (_boundaryNodeRule.isInBoundary(degree)) {
        return true;
      }
    }
    return false;
  }

  bool hasBoundary() {
    return _hasBoundary;
  }

  bool isBoundary(Coordinate pt) {
    if (!_vertexDegree.containsKey(pt)) {
      return false;
    }

    int degree = _vertexDegree.get(pt)!;
    return _boundaryNodeRule.isInBoundary(degree);
  }

  static Map<Coordinate, int> computeBoundaryPoints(List<LineString> lines) {
    Map<Coordinate, int> vertexDegree = {};
    for (LineString line in lines) {
      if (line.isEmpty()) {
        continue;
      }
      addEndpoint(line.getCoordinateN(0), vertexDegree);
      addEndpoint(line.getCoordinateN(line.getNumPoints() - 1), vertexDegree);
    }
    return vertexDegree;
  }

  static void addEndpoint(Coordinate p, Map<Coordinate, int> degree) {
    int dim = 0;
    if (degree.containsKey(p)) {
      dim = degree[p]!;
    }
    dim++;
    degree.put(p, dim);
  }
}
