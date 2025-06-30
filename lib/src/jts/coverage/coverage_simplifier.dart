import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/geom.dart';

import 'corner_area.dart';
import 'coverage_edge.dart';
import 'coverage_ring_edges.dart';
import 'tpvwsimplifier.dart';

class CoverageSimplifier {
  static Array<Geometry> simplifyS(Array<Geometry> coverage, double tolerance) {
    CoverageSimplifier simplifier = CoverageSimplifier(coverage);
    return simplifier.simplify(tolerance);
  }

  static Array<Geometry> simplifyS2(Array<Geometry> coverage, Array<double> tolerances) {
    CoverageSimplifier simplifier = CoverageSimplifier(coverage);
    return simplifier.simplify2(tolerances);
  }

  static Array<Geometry> simplifyInner(Array<Geometry> coverage, double tolerance) {
    CoverageSimplifier simplifier = CoverageSimplifier(coverage);
    return simplifier.simplify3(tolerance, 0);
  }

  static Array<Geometry> simplifyOuter(Array<Geometry> coverage, double tolerance) {
    CoverageSimplifier simplifier = CoverageSimplifier(coverage);
    return simplifier.simplify3(0, tolerance);
  }

  Array<Geometry> coverage;

  double smoothWeight = CornerArea.DEFAULT_SMOOTH_WEIGHT;

  double _removableSizeFactor = 1.0;

  CoverageSimplifier(this.coverage);

  void setRemovableRingSizeFactor(double removableSizeFactor) {
    double factor = removableSizeFactor;
    if (factor < 0.0) {
      factor = 0.0;
    }

    _removableSizeFactor = factor;
  }

  void setSmoothWeight(double smoothWeight) {
    if ((smoothWeight < 0.0) || (smoothWeight > 1.0)) {
      throw IllegalArgumentException("smoothWeight must be in range [0 - 1]");
    }

    this.smoothWeight = smoothWeight;
  }

  Array<Geometry> simplify(double tolerance) {
    return _simplifyEdges2(tolerance, tolerance);
  }

  Array<Geometry> simplify3(double toleranceInner, double toleranceOuter) {
    return _simplifyEdges2(toleranceInner, toleranceOuter);
  }

  Array<Geometry> simplify2(Array<double> tolerances) {
    if (tolerances.length != coverage.length) {
      throw IllegalArgumentException(
          "number of tolerances does not match number of coverage elements");
    }

    return _simplifyEdges(tolerances);
  }

  Array<Geometry> _simplifyEdges(Array<double> tolerances) {
    CoverageRingEdges covRings = CoverageRingEdges.create(coverage);
    List<CoverageEdge> covEdges = covRings.getEdges();
    Array<TPVEdge> edges = _createEdges(covEdges, tolerances);
    return _simplify(covRings, covEdges, edges);
  }

  Array<TPVEdge> _createEdges(List<CoverageEdge> covEdges, Array<double> tolerances) {
    Array<TPVEdge> edges = Array(covEdges.size);
    for (int i = 0; i < covEdges.size; i++) {
      CoverageEdge covEdge = covEdges.get(i);
      double tol = _computeTolerance(covEdge, tolerances);
      edges[i] = _createEdge(covEdge, tol);
    }
    return edges;
  }

  double _computeTolerance(CoverageEdge covEdge, Array<double> tolerances) {
    int index0 = covEdge.getAdjacentIndex(0);
    double tolerance = tolerances[index0];
    if (covEdge.hasAdjacentIndex(1)) {
      int index1 = covEdge.getAdjacentIndex(1);
      double tol1 = tolerances[index1];
      if (tol1 < tolerance) {
        tolerance = tol1;
      }
    }
    return tolerance;
  }

  Array<Geometry> _simplifyEdges2(double toleranceInner, double toleranceOuter) {
    CoverageRingEdges covRings = CoverageRingEdges.create(coverage);
    List<CoverageEdge> covEdges = covRings.getEdges();
    Array<TPVEdge> edges = _createEdgesS(covEdges, toleranceInner, toleranceOuter);
    return _simplify(covRings, covEdges, edges);
  }

  Array<Geometry> _simplify(
      CoverageRingEdges covRings, List<CoverageEdge> covEdges, Array<TPVEdge> edges) {
    CornerArea cornerArea = CornerArea(smoothWeight);
    TPVWSimplifier.simplify(edges, cornerArea, _removableSizeFactor);
    _setCoordinates(covEdges, edges);
    Array<Geometry> result = covRings.buildCoverage();
    return result;
  }

  Array<TPVEdge> _createEdgesS(
      List<CoverageEdge> covEdges, double toleranceInner, double toleranceOuter) {
    Array<TPVEdge> edges = Array(covEdges.size);
    for (int i = 0; i < covEdges.size; i++) {
      CoverageEdge covEdge = covEdges.get(i);
      double tol = _computeToleranceS(covEdge, toleranceInner, toleranceOuter);
      edges[i] = _createEdge(covEdge, tol);
    }
    return edges;
  }

  static TPVEdge _createEdge(CoverageEdge covEdge, double tol) {
    return TPVEdge(covEdge.getCoordinates(), tol, covEdge.isFreeRing(), covEdge.isRemovableRing());
  }

  static double _computeToleranceS(
      CoverageEdge covEdge, double toleranceInner, double toleranceOuter) {
    return covEdge.isInner() ? toleranceInner : toleranceOuter;
  }

  void _setCoordinates(List<CoverageEdge> covEdges, Array<TPVEdge> edges) {
    for (int i = 0; i < covEdges.size; i++) {
      TPVEdge edge = edges[i];
      if (edge.getTolerance() > 0) {
        covEdges.get(i).setCoordinates(edges[i].getCoordinates());
      }
    }
  }
}
