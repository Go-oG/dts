import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/intersection_matrix.dart';
import 'package:dts/src/jts/operation/geometry_graph_operation.dart';

import 'relate_computer.dart';

class RelateOp extends GeometryGraphOperation {
  static IntersectionMatrix relate(Geometry a, Geometry b) {
    RelateOp relOp = RelateOp(a, b);
        IntersectionMatrix im = relOp.getIntersectionMatrix();
        return im;
    }

    static IntersectionMatrix relate2(Geometry a, Geometry b, BoundaryNodeRule boundaryNodeRule) {
        RelateOp relOp = RelateOp(a, b, boundaryNodeRule);
        IntersectionMatrix im = relOp.getIntersectionMatrix();
        return im;
    }

  late final RelateComputer _relate;

  RelateOp(super.g0, super.g1, [super.boundaryNodeRule]) {
    _relate = RelateComputer(arg);
  }

    IntersectionMatrix getIntersectionMatrix() {
        return _relate.computeIM();
    }
}
