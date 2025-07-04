import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/operation/union/unary_union_op.dart';
import 'package:dts/src/jts/operation/union/union_strategy.dart';

import '../overlay/overlay_op.dart';
import 'overlay_ng.dart';
import 'overlay_util.dart';

class UnaryUnionNG {
  static Geometry? union(Geometry geom, PrecisionModel pm) {
    UnaryUnionOp op = UnaryUnionOp.of(geom);
    op.setUnionFunction(createUnionStrategy(pm));
    return op.union();
  }

  static Geometry? union2(List<Geometry> geoms, PrecisionModel pm) {
    UnaryUnionOp op = UnaryUnionOp(geoms);
    op.setUnionFunction(createUnionStrategy(pm));
    return op.union();
  }

  static Geometry? union3(List<Geometry> geoms, GeometryFactory geomFact, PrecisionModel pm) {
    UnaryUnionOp op = UnaryUnionOp(geoms, geomFact);
    op.setUnionFunction(createUnionStrategy(pm));
    return op.union();
  }

  static UnionStrategy createUnionStrategy(PrecisionModel pm) {
    return _UnionStrategy(pm);
  }
}

class _UnionStrategy implements UnionStrategy {
  PrecisionModel pm;

  _UnionStrategy(this.pm);

  @override
  Geometry union(Geometry g0, Geometry g1) {
    return OverlayNG.overlay3(g0, g1, OverlayOpCode.union, pm);
  }

  @override
  bool isdoubleingPrecision() {
    return OverlayUtil.isdoubleing(pm);
  }
}
