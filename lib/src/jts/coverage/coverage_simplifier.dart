import 'package:dts/src/jts/geom/geometry.dart';

import 'corner_area.dart';
import 'coverage_edge.dart';
import 'coverage_ring_edges.dart';
import 'tpvwsimplifier.dart';

class CoverageSimplifier {
  static List<Geometry> simplifyS(List<Geometry> coverage, double tolerance) {
    CoverageSimplifier simplifier = CoverageSimplifier(coverage);
    return simplifier.simplify(tolerance);
  }

  static List<Geometry> simplifyS2(List<Geometry> coverage, List<double> tolerances) {
    CoverageSimplifier simplifier = CoverageSimplifier(coverage);
    return simplifier.simplify2(tolerances);
  }

  static List<Geometry> simplifyInner(List<Geometry> coverage, double tolerance) {
    CoverageSimplifier simplifier = CoverageSimplifier(coverage);
    return simplifier.simplify3(tolerance, 0);
  }

  static List<Geometry> simplifyOuter(List<Geometry> coverage, double tolerance) {
    CoverageSimplifier simplifier = CoverageSimplifier(coverage);
    return simplifier.simplify3(0, tolerance);
  }

  List<Geometry> coverage;

  double smoothWeight = CornerArea.kDefaultSmoothWeight;

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
      throw ArgumentError("smoothWeight must be in range [0 - 1]");
    }

    this.smoothWeight = smoothWeight;
  }

  List<Geometry> simplify(double tolerance) {
    return _simplifyEdges2(tolerance, tolerance);
  }

  List<Geometry> simplify3(double toleranceInner, double toleranceOuter) {
    return _simplifyEdges2(toleranceInner, toleranceOuter);
  }

  List<Geometry> simplify2(List<double> tolerances) {
    if (tolerances.length != coverage.length) {
      throw ArgumentError("number of tolerances does not match number of coverage elements");
    }

    return _simplifyEdges(tolerances);
  }

  List<Geometry> _simplifyEdges(List<double> tolerances) {
    CoverageRingEdges covRings = CoverageRingEdges.create(coverage);
    List<CoverageEdge> covEdges = covRings.getEdges();
    List<TPVEdge> edges = _createEdges(covEdges, tolerances);
    return _simplify(covRings, covEdges, edges);
  }

  List<TPVEdge> _createEdges(List<CoverageEdge> covEdges, List<double> tolerances) {
    List<TPVEdge> edges = [];
    for (var e in covEdges) {
      double tol = _computeTolerance(e, tolerances);
      edges.add(_createEdge(e, tol));
    }
    return edges;
  }

  double _computeTolerance(CoverageEdge covEdge, List<double> tolerances) {
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

  List<Geometry> _simplifyEdges2(double toleranceInner, double toleranceOuter) {
    CoverageRingEdges covRings = CoverageRingEdges.create(coverage);
    List<CoverageEdge> covEdges = covRings.getEdges();
    List<TPVEdge> edges = _createEdgesS(covEdges, toleranceInner, toleranceOuter);
    return _simplify(covRings, covEdges, edges);
  }

  List<Geometry> _simplify(CoverageRingEdges covRings, List<CoverageEdge> covEdges, List<TPVEdge> edges) {
    CornerArea cornerArea = CornerArea(smoothWeight);
    TPVWSimplifier.simplify(edges, cornerArea, _removableSizeFactor);
    _setCoordinates(covEdges, edges);
    return covRings.buildCoverage();
  }

  List<TPVEdge> _createEdgesS(List<CoverageEdge> covEdges, double toleranceInner, double toleranceOuter) {
    List<TPVEdge> edges = [];
    for (var e in covEdges) {
      double tol = _computeToleranceS(e, toleranceInner, toleranceOuter);
      edges.add(_createEdge(e, tol));
    }
    return edges;
  }

  static TPVEdge _createEdge(CoverageEdge covEdge, double tol) {
    return TPVEdge(covEdge.getCoordinates(), tol, covEdge.isFreeRing(), covEdge.isRemovableRing());
  }

  static double _computeToleranceS(CoverageEdge covEdge, double toleranceInner, double toleranceOuter) {
    return covEdge.isInner() ? toleranceInner : toleranceOuter;
  }

  void _setCoordinates(List<CoverageEdge> covEdges, List<TPVEdge> edges) {
    for (int i = 0; i < covEdges.length; i++) {
      TPVEdge edge = edges[i];
      if (edge.getTolerance() > 0) {
        covEdges[i].setCoordinates(edges[i].getCoordinates());
      }
    }
  }
}
