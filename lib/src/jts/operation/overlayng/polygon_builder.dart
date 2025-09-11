import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'maximal_edge_ring.dart';
import 'overlay_edge.dart';
import 'overlay_edge_ring.dart';

class NgPolygonBuilder {
  GeometryFactory geometryFactory;

  final List<OverlayEdgeRing> _shellList = [];

  final List<OverlayEdgeRing> _freeHoleList = [];

  final bool _isEnforcePolygonal;

  NgPolygonBuilder(List<OverlayEdge> resultAreaEdges, this.geometryFactory,
      [this._isEnforcePolygonal = true]) {
    buildRings(resultAreaEdges);
  }

  List<Polygon> getPolygons() {
    return computePolygons(_shellList);
  }

  List<OverlayEdgeRing> getShellRings() {
    return _shellList;
  }

  List<Polygon> computePolygons(List<OverlayEdgeRing> shellList) {
    List<Polygon> resultPolyList = [];
    for (OverlayEdgeRing er in shellList) {
      Polygon poly = er.toPolygon(geometryFactory);
      resultPolyList.add(poly);
    }
    return resultPolyList;
  }

  void buildRings(List<OverlayEdge> resultAreaEdges) {
    linkResultAreaEdgesMax(resultAreaEdges);
    List<NgMaximalEdgeRing> maxRings = buildMaximalRings(resultAreaEdges);
    buildMinimalRings(maxRings);
    placeFreeHoles(_shellList, _freeHoleList);
  }

  void linkResultAreaEdgesMax(List<OverlayEdge> resultEdges) {
    for (OverlayEdge edge in resultEdges) {
      NgMaximalEdgeRing.linkResultAreaMaxRingAtNode(edge);
    }
  }

  static List<NgMaximalEdgeRing> buildMaximalRings(List<OverlayEdge> edges) {
    List<NgMaximalEdgeRing> edgeRings = [];
    for (OverlayEdge e in edges) {
      if (e.isInResultArea() && e.getLabel().isBoundaryEither()) {
        if (e.getEdgeRingMax() == null) {
          NgMaximalEdgeRing er = NgMaximalEdgeRing(e);
          edgeRings.add(er);
        }
      }
    }
    return edgeRings;
  }

  void buildMinimalRings(List<NgMaximalEdgeRing> maxRings) {
    for (NgMaximalEdgeRing erMax in maxRings) {
      List<OverlayEdgeRing> minRings = erMax.buildMinimalRings(geometryFactory);
      assignShellsAndHoles(minRings);
    }
  }

  void assignShellsAndHoles(List<OverlayEdgeRing> minRings) {
    OverlayEdgeRing? shell = findSingleShell(minRings);
    if (shell != null) {
      assignHoles(shell, minRings);
      _shellList.add(shell);
    } else {
      _freeHoleList.addAll(minRings);
    }
  }

  OverlayEdgeRing? findSingleShell(List<OverlayEdgeRing> edgeRings) {
    int shellCount = 0;
    OverlayEdgeRing? shell;
    for (OverlayEdgeRing er in edgeRings) {
      if (!er.isHole) {
        shell = er;
        shellCount++;
      }
    }
    Assert.isTrue(shellCount <= 1, "found two shells in EdgeRing list");
    return shell;
  }

  static void assignHoles(
      OverlayEdgeRing shell, List<OverlayEdgeRing> edgeRings) {
    for (OverlayEdgeRing er in edgeRings) {
      if (er.isHole) {
        er.setShell(shell);
      }
    }
  }

  void placeFreeHoles(
      List<OverlayEdgeRing> shellList, List<OverlayEdgeRing> freeHoleList) {
    for (OverlayEdgeRing hole in freeHoleList) {
      if (hole.getShell() == null) {
        OverlayEdgeRing? shell = hole.findEdgeRingContaining(shellList);
        if (_isEnforcePolygonal && (shell == null)) {
          throw TopologyException(
              "unable to assign free hole to a shell", hole.getCoordinate());
        }
        hole.setShell(shell);
      }
    }
  }
}
