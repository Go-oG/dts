import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/intersection_matrix.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/noding/mcindex_segment_set_mutual_intersector.dart';

import '../../geom/geom_collection.dart';
import 'dimension_location.dart';
import 'edge_segment_intersector.dart';
import 'edge_set_intersector.dart';
import 'relate_geometry.dart';
import 'relate_matrix_predicate.dart';
import 'relate_predicate.dart';
import 'relate_segment_string.dart';
import 'topology_computer.dart';
import 'topology_predicate.dart';

class RelateNG {
  static bool relate4(Geometry a, Geometry b, TopologyPredicate pred) {
    RelateNG rng = RelateNG(a, false);
    return rng.evaluate3(b, pred);
  }

  static bool relate5(Geometry a, Geometry b, TopologyPredicate pred, BoundaryNodeRule bnRule) {
    RelateNG rng = RelateNG(a, false, bnRule);
    return rng.evaluate3(b, pred);
  }

  static bool relate3(Geometry a, Geometry b, String imPattern) {
    RelateNG rng = RelateNG(a, false);
    return rng.evaluate2(b, imPattern);
  }

  static IntersectionMatrix relate(Geometry a, Geometry b) {
    RelateNG rng = RelateNG(a, false);
    return rng.evaluate(b);
  }

  static IntersectionMatrix relate2(Geometry a, Geometry b, BoundaryNodeRule bnRule) {
    RelateNG rng = RelateNG(a, false, bnRule);
    return rng.evaluate(b);
  }

  static RelateNG prepare(Geometry a) {
    return RelateNG(a, true);
  }

  static RelateNG prepare2(Geometry a, BoundaryNodeRule bnRule) {
    return RelateNG(a, true, bnRule);
  }

  late BoundaryNodeRule boundaryNodeRule;

  late RelateGeometry _geomA;

  MCIndexSegmentSetMutualIntersector? _edgeMutualInt;

  RelateNG(Geometry inputA, bool isPrepared, [BoundaryNodeRule? bnRule]) {
    boundaryNodeRule = bnRule ?? BoundaryNodeRule.ogcSfsBR;
    _geomA = RelateGeometry(inputA, isPrepared, boundaryNodeRule);
  }

  IntersectionMatrix evaluate(Geometry b) {
    final rel = RelateMatrixPredicate();
    evaluate3(b, rel);
    return rel.getIM();
  }

  bool evaluate2(Geometry b, String imPattern) {
    return evaluate3(b, RelatePredicate.matches(imPattern));
  }

  bool evaluate3(Geometry b, TopologyPredicate predicate) {
    if (!hasRequiredEnvelopeInteraction(b, predicate)) {
      return false;
    }
    RelateGeometry geomB = RelateGeometry.of(b, boundaryNodeRule);
    int dimA = _geomA.getDimensionReal();
    int dimB = geomB.getDimensionReal();
    predicate.init(dimA, dimB);
    if (predicate.isKnown()) {
      return finishValue(predicate);
    }

    predicate.init2(_geomA.getEnvelope(), geomB.getEnvelope());
    if (predicate.isKnown()) {
      return finishValue(predicate);
    }

    final topoComputer = TopologyComputer(predicate, _geomA, geomB);
    if ((dimA == Dimension.P) && (dimB == Dimension.P)) {
      computePP(geomB, topoComputer);
      topoComputer.finish();
      return topoComputer.getResult();
    }
    computeAtPoints(geomB, RelateGeometry.GEOM_B, _geomA, topoComputer);
    if (topoComputer.isResultKnown()) {
      return topoComputer.getResult();
    }
    computeAtPoints(_geomA, RelateGeometry.GEOM_A, geomB, topoComputer);
    if (topoComputer.isResultKnown()) {
      return topoComputer.getResult();
    }
    if (_geomA.hasEdges() && geomB.hasEdges()) {
      computeAtEdges(geomB, topoComputer);
    }
    topoComputer.finish();
    return topoComputer.getResult();
  }

  bool hasRequiredEnvelopeInteraction(Geometry b, TopologyPredicate predicate) {
    Envelope envB = b.getEnvelopeInternal();
    bool isInteracts = false;
    if (predicate.requireCovers(RelateGeometry.GEOM_A)) {
      if (!_geomA.getEnvelope().covers(envB)) {
        return false;
      }
      isInteracts = true;
    } else if (predicate.requireCovers(RelateGeometry.GEOM_B)) {
      if (!envB.covers(_geomA.getEnvelope())) {
        return false;
      }
      isInteracts = true;
    }
    if (((!isInteracts) && predicate.requireInteraction()) &&
        (!_geomA.getEnvelope().intersects(envB))) {
      return false;
    }
    return true;
  }

  bool finishValue(TopologyPredicate predicate) {
    predicate.finish();
    return predicate.value();
  }

  void computePP(RelateGeometry geomB, TopologyComputer topoComputer) {
    Set<Coordinate> ptsA = _geomA.getUniquePoints();
    Set<Coordinate> ptsB = geomB.getUniquePoints();
    int numBinA = 0;
    for (Coordinate ptB in ptsB) {
      if (ptsA.contains(ptB)) {
        numBinA++;
        topoComputer.addPointOnPointInterior(ptB);
      } else {
        topoComputer.addPointOnPointExterior(RelateGeometry.GEOM_B, ptB);
      }
      if (topoComputer.isResultKnown()) {
        return;
      }
    }
    if (numBinA < ptsA.length) {
      topoComputer.addPointOnPointExterior(RelateGeometry.GEOM_A, null);
    }
  }

  void computeAtPoints(
      RelateGeometry geom, bool isA, RelateGeometry geomTarget, TopologyComputer topoComputer) {
    bool isResultKnown = false;
    isResultKnown = computePoints(geom, isA, geomTarget, topoComputer);
    if (isResultKnown) {
      return;
    }

    bool checkDisjointPoints =
        geomTarget.hasDimension(Dimension.A) || topoComputer.isExteriorCheckRequired(isA);
    if (!checkDisjointPoints) {
      return;
    }

    isResultKnown = computeLineEnds(geom, isA, geomTarget, topoComputer);
    if (isResultKnown) {
      return;
    }

    computeAreaVertex(geom, isA, geomTarget, topoComputer);
  }

  bool computePoints(
      RelateGeometry geom, bool isA, RelateGeometry geomTarget, TopologyComputer topoComputer) {
    if (!geom.hasDimension(Dimension.P)) {
      return false;
    }
    List<Point> points = geom.getEffectivePoints();
    for (Point point in points) {
      if (point.isEmpty()) {
        continue;
      }

      Coordinate pt = point.getCoordinate()!;
      computePoint(isA, pt, geomTarget, topoComputer);
      if (topoComputer.isResultKnown()) {
        return true;
      }
    }
    return false;
  }

  void computePoint(
      bool isA, Coordinate pt, RelateGeometry geomTarget, TopologyComputer topoComputer) {
    int locDimTarget = geomTarget.locateWithDim(pt);
    int locTarget = DimensionLocation.location(locDimTarget);
    int dimTarget = DimensionLocation.dimension2(locDimTarget, topoComputer.getDimension(!isA));
    topoComputer.addPointOnGeometry(isA, locTarget, dimTarget, pt);
  }

  bool computeLineEnds(
      RelateGeometry geom, bool isA, RelateGeometry geomTarget, TopologyComputer topoComputer) {
    if (!geom.hasDimension(Dimension.L)) {
      return false;
    }
    bool hasExteriorIntersection = false;
    final geomi = GeometryCollectionIterator(geom.getGeometry());
    while (geomi.moveNext()) {
      Geometry elem = geomi.current;
      if (elem.isEmpty()) {
        continue;
      }

      if (elem is LineString) {
        if (hasExteriorIntersection &&
            elem.getEnvelopeInternal().disjoint(geomTarget.getEnvelope())) {
          continue;
        }

        LineString line = elem;
        Coordinate e0 = line.getCoordinateN(0);
        hasExteriorIntersection |= computeLineEnd(geom, isA, e0, geomTarget, topoComputer);
        if (topoComputer.isResultKnown()) {
          return true;
        }
        if (!line.isClosed()) {
          Coordinate e1 = line.getCoordinateN(line.getNumPoints() - 1);
          hasExteriorIntersection |= computeLineEnd(geom, isA, e1, geomTarget, topoComputer);
          if (topoComputer.isResultKnown()) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool computeLineEnd(
    RelateGeometry geom,
    bool isA,
    Coordinate pt,
    RelateGeometry geomTarget,
    TopologyComputer topoComputer,
  ) {
    int locDimLineEnd = geom.locateLineEndWithDim(pt);
    int dimLineEnd = DimensionLocation.dimension2(locDimLineEnd, topoComputer.getDimension(isA));
    if (dimLineEnd != Dimension.L) {
      return false;
    }

    int locLineEnd = DimensionLocation.location(locDimLineEnd);
    int locDimTarget = geomTarget.locateWithDim(pt);
    int locTarget = DimensionLocation.location(locDimTarget);
    int dimTarget = DimensionLocation.dimension2(locDimTarget, topoComputer.getDimension(!isA));
    topoComputer.addLineEndOnGeometry(isA, locLineEnd, locTarget, dimTarget, pt);
    return locTarget == Location.exterior;
  }

  bool computeAreaVertex(
      RelateGeometry geom, bool isA, RelateGeometry geomTarget, TopologyComputer topoComputer) {
    if (!geom.hasDimension(Dimension.A)) {
      return false;
    }
    if (geomTarget.getDimension() < Dimension.L) {
      return false;
    }

    bool hasExteriorIntersection = false;
    final geomi = GeometryCollectionIterator(geom.getGeometry());
    while (geomi.moveNext()) {
      Geometry elem = geomi.current;
      if (elem.isEmpty()) {
        continue;
      }

      if (elem is Polygon) {
        if (hasExteriorIntersection &&
            elem.getEnvelopeInternal().disjoint(geomTarget.getEnvelope())) {
          continue;
        }

        Polygon poly = elem;
        hasExteriorIntersection |=
            computeAreaVertex2(geom, isA, poly.getExteriorRing(), geomTarget, topoComputer);
        if (topoComputer.isResultKnown()) {
          return true;
        }
        for (int j = 0; j < poly.getNumInteriorRing(); j++) {
          hasExteriorIntersection |=
              computeAreaVertex2(geom, isA, poly.getInteriorRingN(j), geomTarget, topoComputer);
          if (topoComputer.isResultKnown()) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool computeAreaVertex2(
    RelateGeometry geom,
    bool isA,
    LinearRing ring,
    RelateGeometry geomTarget,
    TopologyComputer topoComputer,
  ) {
    final pt = ring.getCoordinate()!;
    int locArea = geom.locateAreaVertex(pt);
    int locDimTarget = geomTarget.locateWithDim(pt);
    int locTarget = DimensionLocation.location(locDimTarget);
    int dimTarget = DimensionLocation.dimension2(locDimTarget, topoComputer.getDimension(!isA));
    topoComputer.addAreaVertex(isA, locArea, locTarget, dimTarget, pt);
    return locTarget == Location.exterior;
  }

  void computeAtEdges(RelateGeometry geomB, TopologyComputer topoComputer) {
    Envelope envInt = _geomA.getEnvelope().intersection(geomB.getEnvelope());
    if (envInt.isNull) {
      return;
    }

    List<RelateSegmentString> edgesB = geomB.extractSegmentStrings(RelateGeometry.GEOM_B, envInt);
    final intersector = EdgeSegmentIntersector(topoComputer);
    if (topoComputer.isSelfNodingRequired()) {
      computeEdgesAll(edgesB, envInt, intersector);
    } else {
      computeEdgesMutual(edgesB, envInt, intersector);
    }
    if (topoComputer.isResultKnown()) {
      return;
    }
    topoComputer.evaluateNodes();
  }

  void computeEdgesAll(
      List<RelateSegmentString> edgesB, Envelope envInt, EdgeSegmentIntersector intersector) {
    List<RelateSegmentString> edgesA = _geomA.extractSegmentStrings(RelateGeometry.GEOM_A, envInt);
    final edgeInt = OpEdgeSetIntersector(edgesA, edgesB, envInt);
    edgeInt.process(intersector);
  }

  void computeEdgesMutual(
      List<RelateSegmentString> edgesB, Envelope envInt, EdgeSegmentIntersector intersector) {
    if (_edgeMutualInt == null) {
      Envelope? envExtract = (_geomA.isPrepared()) ? null : envInt;
      List<RelateSegmentString> edgesA =
          _geomA.extractSegmentStrings(RelateGeometry.GEOM_A, envExtract);
      _edgeMutualInt = MCIndexSegmentSetMutualIntersector.of(edgesA, envExtract);
    }
    _edgeMutualInt!.process(edgesB, intersector);
  }
}
