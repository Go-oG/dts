import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/index/kd_tree.dart';

class SnappingPointIndex {
  double snapTolerance;

  late KdTree _snapPointIndex;

  SnappingPointIndex(this.snapTolerance) {
    _snapPointIndex = KdTree(snapTolerance);
  }

  Coordinate snap(Coordinate p) {
    KdNode node = _snapPointIndex.insert(p);
    return node.getCoordinate();
  }

  double getTolerance() {
    return snapTolerance;
  }

  int depth() {
    return _snapPointIndex.depth();
  }
}
