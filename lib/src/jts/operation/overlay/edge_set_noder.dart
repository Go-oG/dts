import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/index/edge_set_intersector.dart';
import 'package:dts/src/jts/geomgraph/index/segment_intersector.dart';

class EdgeSetNoder {
  LineIntersector li;

  final List<Edge> _inputEdges = [];

  EdgeSetNoder(this.li);

  void addEdges(List<Edge> edges) {
    _inputEdges.addAll(edges);
  }

  List<Edge> getNodedEdges() {
    EdgeSetIntersector esi = SimpleMCSweepLineIntersector();
    SegmentIntersector si = SegmentIntersector(li, true, false);
    esi.computeIntersections(_inputEdges, si, true);
    List<Edge> splitEdges = [];
    for (var e in _inputEdges) {
      e.getEdgeIntersectionList().addSplitEdges(splitEdges);
    }
    return splitEdges;
  }
}
