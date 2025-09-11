import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geomgraph/node.dart';
import 'package:dts/src/jts/geomgraph/node_factory.dart';

import '../../geomgraph/edge.dart';

class BufferNodeFactory extends NodeFactory {
  @override
  Node createNode(Coordinate coord) {
    return Node(coord, DirectedEdgeStar());
  }
}
