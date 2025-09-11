import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/location.dart';

import 'basic_predicate.dart';
import 'impattern_matcher.dart';
import 'impredicate.dart';
import 'relate_geometry.dart';
import 'topology_predicate.dart';

abstract class RelatePredicate {
  static TopologyPredicate intersects() {
    return _Intersects();
  }

  static TopologyPredicate disjoint() {
    return _Disjoint();
  }

  static TopologyPredicate contains() {
    return _Contains();
  }

  static TopologyPredicate within() {
    return _WithIn();
  }

  static TopologyPredicate covers() {
    return _Covers();
  }

  static TopologyPredicate coveredBy() {
    return _CoveredBy();
  }

  static TopologyPredicate crosses() {
    return _Crosses();
  }

  static TopologyPredicate equalsTopo() {
    return _EqualsTopo();
  }

  static TopologyPredicate overlaps() {
    return _Overlaps();
  }

  static TopologyPredicate touches() {
    return _Touches();
  }

  static TopologyPredicate matches(String imPattern) {
    return IMPatternMatcher(imPattern);
  }
}

class _Intersects extends BasicPredicate {
  @override
  String name() {
    return "intersects";
  }

  @override
  bool requireSelfNoding() {
    return false;
  }

  @override
  bool requireExteriorCheck(bool isSourceA) {
    return false;
  }

  @override
  void init2(Envelope envA, Envelope envB) {
    require(envA.intersects(envB));
  }

  @override
  void updateDimension(int locA, int locB, int dimension) {
    setValueIf(true, BasicPredicate.isIntersection(locA, locB));
  }

  @override
  void finish() {
    setValue2(false);
  }
}

class _Disjoint extends BasicPredicate {
  @override
  String name() {
    return "disjoint";
  }

  @override
  bool requireSelfNoding() {
    return false;
  }

  @override
  bool requireInteraction() {
    return false;
  }

  @override
  bool requireExteriorCheck(bool isSourceA) {
    return false;
  }

  @override
  void init2(Envelope envA, Envelope envB) {
    setValueIf(true, envA.disjoint(envB));
  }

  @override
  void updateDimension(int locA, int locB, int dimension) {
    setValueIf(false, BasicPredicate.isIntersection(locA, locB));
  }

  @override
  void finish() {
    setValue2(true);
  }
}

class _Contains extends IMPredicate {
  @override
  String name() {
    return "contains";
  }

  @override
  bool requireCovers(bool isSourceA) {
    return isSourceA == RelateGeometry.kGeomA;
  }

  @override
  bool requireExteriorCheck(bool isSourceA) {
    return isSourceA == RelateGeometry.kGeomB;
  }

  @override
  void init(int dimA, int dimB) {
    super.init(dimA, dimB);
    require(IMPredicate.isDimsCompatibleWithCovers(dimA, dimB));
  }

  @override
  void init2(Envelope envA, Envelope envB) {
    requireCovers2(envA, envB);
  }

  @override
  bool isDetermined() {
    return intersectsExteriorOf(RelateGeometry.kGeomA);
  }

  @override
  bool valueIM() {
    return intMatrix.isContains();
  }
}

class _WithIn extends IMPredicate {
  @override
  String name() {
    return "within";
  }

  @override
  bool requireCovers(bool isSourceA) {
    return isSourceA == RelateGeometry.kGeomB;
  }

  @override
  bool requireExteriorCheck(bool isSourceA) {
    return isSourceA == RelateGeometry.kGeomA;
  }

  @override
  void init(int dimA, int dimB) {
    super.init(dimA, dimB);
    require(IMPredicate.isDimsCompatibleWithCovers(dimB, dimA));
  }

  @override
  void init2(Envelope envA, Envelope envB) {
    requireCovers2(envB, envA);
  }

  @override
  bool isDetermined() {
    return intersectsExteriorOf(RelateGeometry.kGeomB);
  }

  @override
  bool valueIM() {
    return intMatrix.isWithin();
  }
}

class _Covers extends IMPredicate {
  @override
  String name() {
    return "covers";
  }

  @override
  bool requireCovers(bool isSourceA) {
    return isSourceA == RelateGeometry.kGeomA;
  }

  @override
  bool requireExteriorCheck(bool isSourceA) {
    return isSourceA == RelateGeometry.kGeomB;
  }

  @override
  void init(int dimA, int dimB) {
    super.init(dimA, dimB);
    require(IMPredicate.isDimsCompatibleWithCovers(dimA, dimB));
  }

  @override
  void init2(Envelope envA, Envelope envB) {
    requireCovers2(envA, envB);
  }

  @override
  bool isDetermined() {
    return intersectsExteriorOf(RelateGeometry.kGeomA);
  }

  @override
  bool valueIM() {
    return intMatrix.isCovers();
  }
}

class _CoveredBy extends IMPredicate {
  @override
  String name() {
    return "coveredBy";
  }

  @override
  bool requireCovers(bool isSourceA) {
    return isSourceA == RelateGeometry.kGeomB;
  }

  @override
  bool requireExteriorCheck(bool isSourceA) {
    return isSourceA == RelateGeometry.kGeomA;
  }

  @override
  void init(int dimA, int dimB) {
    super.init(dimA, dimB);
    require(IMPredicate.isDimsCompatibleWithCovers(dimB, dimA));
  }

  @override
  void init2(Envelope envA, Envelope envB) {
    requireCovers2(envB, envA);
  }

  @override
  bool isDetermined() {
    return intersectsExteriorOf(RelateGeometry.kGeomB);
  }

  @override
  bool valueIM() {
    return intMatrix.isCoveredBy();
  }
}

class _Crosses extends IMPredicate {
  @override
  String name() {
    return "crosses";
  }

  @override
  void init(int dimA, int dimB) {
    super.init(dimA, dimB);
    bool isBothPointsOrAreas =
        ((dimA == Dimension.P) && (dimB == Dimension.P)) ||
            ((dimA == Dimension.A) && (dimB == Dimension.A));
    require(!isBothPointsOrAreas);
  }

  @override
  bool isDetermined() {
    if ((dimA == Dimension.L) && (dimB == Dimension.L)) {
      if (getDimension(Location.interior, Location.interior) > Dimension.P) {
        return true;
      }
    } else if (dimA < dimB) {
      if (isIntersects(Location.interior, Location.interior) &&
          isIntersects(Location.interior, Location.exterior)) {
        return true;
      }
    } else if (dimA > dimB) {
      if (isIntersects(Location.interior, Location.interior) &&
          isIntersects(Location.exterior, Location.interior)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool valueIM() {
    return intMatrix.isCrosses(dimA, dimB);
  }
}

class _EqualsTopo extends IMPredicate {
  @override
  String name() {
    return "equals";
  }

  @override
  bool requireInteraction() {
    return false;
  }

  @override
  void init2(Envelope envA, Envelope envB) {
    setValueIf(true, envA.isNull && envB.isNull);
    require(envA == envB);
  }

  @override
  bool isDetermined() {
    bool isEitherExteriorIntersects =
        ((isIntersects(Location.interior, Location.exterior) ||
                    isIntersects(Location.boundary, Location.exterior)) ||
                isIntersects(Location.exterior, Location.interior)) ||
            isIntersects(Location.exterior, Location.boundary);
    return isEitherExteriorIntersects;
  }

  @override
  bool valueIM() {
    return intMatrix.isEquals(dimA, dimB);
  }
}

class _Overlaps extends IMPredicate {
  @override
  String name() {
    return "overlaps";
  }

  @override
  void init(int dimA, int dimB) {
    super.init(dimA, dimB);
    require(dimA == dimB);
  }

  @override
  bool isDetermined() {
    if ((dimA == Dimension.A) || (dimA == Dimension.P)) {
      if ((isIntersects(Location.interior, Location.interior) &&
              isIntersects(Location.interior, Location.exterior)) &&
          isIntersects(Location.exterior, Location.interior)) {
        return true;
      }
    }
    if (dimA == Dimension.L) {
      if ((isDimension(Location.interior, Location.interior, Dimension.L) &&
              isIntersects(Location.interior, Location.exterior)) &&
          isIntersects(Location.exterior, Location.interior)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool valueIM() {
    return intMatrix.isOverlaps(dimA, dimB);
  }
}

class _Touches extends IMPredicate {
  @override
  String name() {
    return "touches";
  }

  @override
  void init(int dimA, int dimB) {
    super.init(dimA, dimB);
    bool isBothPoints = (dimA == 0) && (dimB == 0);
    require(!isBothPoints);
  }

  @override
  bool isDetermined() {
    bool isInteriorsIntersects =
        isIntersects(Location.interior, Location.interior);
    return isInteriorsIntersects;
  }

  @override
  bool valueIM() {
    return intMatrix.isTouches(dimA, dimB);
  }
}
