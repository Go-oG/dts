import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/intersection_matrix.dart';
import 'package:dts/src/jts/geom/location.dart';

import 'basic_predicate.dart';

abstract class IMPredicate extends BasicPredicate {
  static bool isDimsCompatibleWithCovers(int dim0, int dim1) {
    if ((dim0 == Dimension.P) && (dim1 == Dimension.L)) {
      return true;
    }

    return dim0 >= dim1;
  }

  static const int _dimUnknown = Dimension.kDontCare;

  int dimA = 0;

  int dimB = 0;

  late final IntersectionMatrix intMatrix;

  IMPredicate() {
    intMatrix = IntersectionMatrix();
    intMatrix.set2(Location.exterior, Location.exterior, Dimension.A);
  }

  @override
  void init(int dimA, int dimB) {
    this.dimA = dimA;
    this.dimB = dimB;
  }

  @override
  void updateDimension(int locA, int locB, int dimension) {
    if (isDimChanged(locA, locB, dimension)) {
      intMatrix.set2(locA, locB, dimension);
      if (isDetermined()) {
        setValue2(valueIM());
      }
    }
  }

  bool isDimChanged(int locA, int locB, int dimension) {
    return dimension > intMatrix.get(locA, locB);
  }

  bool isDetermined();

  bool intersectsExteriorOf(bool isA) {
    if (isA) {
      return isIntersects(Location.exterior, Location.interior) || isIntersects(Location.exterior, Location.boundary);
    } else {
      return isIntersects(Location.interior, Location.exterior) || isIntersects(Location.boundary, Location.exterior);
    }
  }

  bool isIntersects(int locA, int locB) {
    return intMatrix.get(locA, locB) >= Dimension.P;
  }

  bool isKnown3(int locA, int locB) {
    return intMatrix.get(locA, locB) != _dimUnknown;
  }

  bool isDimension(int locA, int locB, int dimension) {
    return intMatrix.get(locA, locB) == dimension;
  }

  int getDimension(int locA, int locB) {
    return intMatrix.get(locA, locB);
  }

  @override
  void finish() {
    setValue2(valueIM());
  }

  bool valueIM();
}
