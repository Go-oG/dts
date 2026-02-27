import 'package:dts/src/jts/geom/intersection_matrix.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';

import 'edge_end_bundle.dart';

class EdgeEndBundleStar extends EdgeEndStar {
  @override
  void insert(EdgeEnd e) {
    EdgeEndBundle? eb = edgeMap[e] as EdgeEndBundle?;
    if (eb == null) {
      eb = EdgeEndBundle(e);
      insertEdgeEnd(e, eb);
    } else {
      eb.insert(e);
    }
  }

  void updateIM(IntersectionMatrix im) {
    for (var it in iterator()) {
      EdgeEndBundle esb = it as EdgeEndBundle;
      esb.updateIM(im);
    }
  }
}
