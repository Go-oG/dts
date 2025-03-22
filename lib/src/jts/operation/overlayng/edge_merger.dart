import 'package:dts/src/jts/util/assert.dart';

import 'edge.dart';
import 'edge_key.dart';

class EdgeMerger {
  static List<OEdge> merge(List<OEdge> edges) {
    List<OEdge> mergedEdges = [];
    Map<EdgeKey, OEdge> edgeMap = {};
    for (OEdge edge in edges) {
      EdgeKey edgeKey = EdgeKey.create(edge);
      OEdge? baseEdge = edgeMap[edgeKey];
      if (baseEdge == null) {
        edgeMap[edgeKey]=edge;
        mergedEdges.add(edge);
      } else {
        Assert.isTrue2(baseEdge.size() == edge.size(), "Merge of edges of different sizes - probable noding error.");
        baseEdge.merge(edge);
      }
    }
    return mergedEdges;
  }
}
