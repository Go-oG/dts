import 'package:dts/src/jts/geom/intersection_matrix.dart';
import 'package:dts/src/jts/geomgraph/node.dart';

import 'edge_end_bundle_star.dart';

class RelateNode extends Node {
  RelateNode(super.coord, super.edges);

  @override
  void computeIM(IntersectionMatrix im) {
    im.setAtLeastIfValid(label!.getLocation(0), label!.getLocation(1), 0);
  }

  void updateIMFromEdges(IntersectionMatrix im) {
    (edges as EdgeEndBundleStar).updateIM(im);
  }
}
