import 'package:dts/src/jts/algorithm/point_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geomgraph/label.dart';
import 'package:dts/src/jts/geomgraph/node.dart';

import 'overlay_op.dart';

class PointBuilder {
  OverlayOp op;

  GeomFactory geometryFactory;

  List<Point> resultPointList = [];

  PointBuilder(this.op, this.geometryFactory, PointLocator ptLocator);

  List<Point> build(OverlayOpCode opCode) {
    extractNonCoveredResultNodes(opCode);
    return resultPointList;
  }

  void extractNonCoveredResultNodes(OverlayOpCode opCode) {
    for (var n in op.getGraph().getNodes()) {
      if (n.isInResult) continue;
      if (n.isIncidentEdgeInResult()) continue;

      if ((n.getEdges()!.getDegree() == 0) || (opCode == OverlayOpCode.intersection)) {
        Label label = n.label!;
        if (OverlayOp.isResultOfOp(label, opCode)) {
          filterCoveredNodeToPoint(n);
        }
      }
    }
  }

  void filterCoveredNodeToPoint(Node n) {
    Coordinate coord = n.getCoordinate();
    if (!op.isCoveredByLA(coord)) {
      Point pt = geometryFactory.createPoint2(coord);
      resultPointList.add(pt);
    }
  }
}
