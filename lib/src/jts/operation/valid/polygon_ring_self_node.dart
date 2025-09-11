import 'package:dts/src/jts/algorithm/polygon_node_topology.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

class PolygonRingSelfNode {
  Coordinate nodePt;

  final Coordinate _e00;

  final Coordinate _e01;

  final Coordinate _e10;

  PolygonRingSelfNode(
      this.nodePt, this._e00, this._e01, this._e10, Coordinate e11);

  Coordinate getCoordinate() {
    return nodePt;
  }

  bool isExterior(bool isInteriorOnRight) {
    bool isInteriorSeg =
        PolygonNodeTopology.isInteriorSegment(nodePt, _e00, _e01, _e10);
    bool isExterior = (isInteriorOnRight) ? !isInteriorSeg : isInteriorSeg;
    return isExterior;
  }
}
