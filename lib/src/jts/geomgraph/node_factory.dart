import 'package:dts/src/jts/geom/coordinate.dart';
import 'node.dart';

class NodeFactory {
  Node createNode(Coordinate coord) {
    return Node(coord, null);
  }
}
