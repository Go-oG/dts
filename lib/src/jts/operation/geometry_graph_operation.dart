import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geomgraph/geometry_graph.dart';

class GeometryGraphOperation {
  final LineIntersector li = RobustLineIntersector();

  late PrecisionModel resultPrecisionModel;

  late Array<GeometryGraph> arg;

  GeometryGraphOperation(Geometry g0, Geometry g1, [BoundaryNodeRule? boundaryNodeRule]) {
    boundaryNodeRule ??= BoundaryNodeRule.ogcSfsBR;
    if (g0.getPrecisionModel().compareTo(g1.getPrecisionModel()) >= 0) {
      setComputationPrecision(g0.getPrecisionModel());
    } else {
      setComputationPrecision(g1.getPrecisionModel());
    }

    arg = Array(2);
    arg[0] = GeometryGraph(0, g0, boundaryNodeRule);
    arg[1] = GeometryGraph(1, g1, boundaryNodeRule);
  }

  GeometryGraphOperation.of(Geometry g0) {
    setComputationPrecision(g0.getPrecisionModel());
    arg = Array(1);
    arg[0] = GeometryGraph.of(0, g0);
  }

  Geometry? getArgGeometry(int i) {
    return arg[i].getGeometry();
  }

  void setComputationPrecision(PrecisionModel pm) {
    resultPrecisionModel = pm;
    li.setPrecisionModel(resultPrecisionModel);
  }
}
