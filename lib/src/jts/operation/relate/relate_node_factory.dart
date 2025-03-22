import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geomgraph/node.dart';
import 'package:dts/src/jts/geomgraph/node_factory.dart';

import 'edge_end_bundle_star.dart';
import 'relate_node.dart';

class RelateNodeFactory extends NodeFactory {
  @override
  Node createNode(Coordinate coord) {
    return RelateNode(coord, EdgeEndBundleStar());
    }
}
