import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/node.dart';
import 'package:dts/src/jts/geomgraph/node_factory.dart';


 class OverlayNodeFactory extends NodeFactory {
    @override
  Node createNode(Coordinate coord) {
        return Node(coord, DirectedEdgeStar());
    }
}
