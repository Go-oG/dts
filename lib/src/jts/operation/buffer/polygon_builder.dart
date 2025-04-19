import 'package:dts/src/jts/algorithm/point_location.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/edge_ring.dart';
import 'package:dts/src/jts/geomgraph/planar_graph.dart';
import 'package:dts/src/jts/util/assert.dart';

import '../../geomgraph/node.dart';
import '../buffer/maximal_edge_ring.dart';
import 'minimal_edge_ring.dart';

class PolygonBuilder {
  GeometryFactory geometryFactory;

  final List<EdgeRing> _shellList = [];

  PolygonBuilder(this.geometryFactory);

  void add(PGPlanarGraph graph) {
    addAll(graph.getEdgeEnds().cast(), graph.getNodes());
  }

  void addAll(List<DirectedEdge> dirEdges, Iterable<Node> nodes) {
    PGPlanarGraph.linkResultDirectedEdges2(nodes);
    List<MaximalEdgeRing> maxEdgeRings = buildMaximalEdgeRings(dirEdges);
    List<MinimalEdgeRing> freeHoleList = [];
    List<EdgeRing> edgeRings = buildMinimalEdgeRings(maxEdgeRings, _shellList, freeHoleList);
    sortShellsAndHoles(edgeRings, _shellList, freeHoleList);
    placeFreeHoles(_shellList, freeHoleList);
  }

  List<Geometry> getPolygons() {
    return computePolygons(_shellList);
  }

  List<MaximalEdgeRing> buildMaximalEdgeRings(List<DirectedEdge> dirEdges) {
    List<MaximalEdgeRing> maxEdgeRings = [];
    for (var de in dirEdges) {
      if (de.isInResult() && de.getLabel()!.isArea()) {
        if (de.getEdgeRing() == null) {
          final er = MaximalEdgeRing(de, geometryFactory);
          maxEdgeRings.add(er);
          er.setInResult();
        }
      }
    }
    return maxEdgeRings;
  }

  List<MaximalEdgeRing> buildMinimalEdgeRings(
    List<MaximalEdgeRing> maxEdgeRings,
    List<EdgeRing> shellList,
    List<MinimalEdgeRing> freeHoleList,
  ) {
    List<MaximalEdgeRing> edgeRings = [];
    for (var er in maxEdgeRings) {
      if (er.getMaxNodeDegree() > 2) {
        er.linkDirectedEdgesForMinimalEdgeRings();
        List<MinimalEdgeRing> minEdgeRings = er.buildMinimalRings();
        EdgeRing? shell = findShell(minEdgeRings);
        if (shell != null) {
          placePolygonHoles(shell, minEdgeRings);
          shellList.add(shell);
        } else {
          freeHoleList.addAll(minEdgeRings);
        }
      } else {
        edgeRings.add(er);
      }
    }
    return edgeRings;
  }

  EdgeRing? findShell(List<EdgeRing> minEdgeRings) {
    int shellCount = 0;
    EdgeRing? shell;
    for (var er in minEdgeRings) {
      if (!er.isHole()) {
        shell = er;
        shellCount++;
      }
    }
    Assert.isTrue2(shellCount <= 1, "found two shells in MinimalEdgeRing list");
    return shell;
  }

  void placePolygonHoles(EdgeRing shell, List<MinimalEdgeRing> minEdgeRings) {
    for (var er in minEdgeRings) {
      if (er.isHole()) {
        er.setShell(shell);
      }
    }
  }

  void sortShellsAndHoles(
      List<EdgeRing> edgeRings, List<EdgeRing> shellList, List<EdgeRing> freeHoleList) {
    for (var er in edgeRings) {
      if (er.isHole()) {
        freeHoleList.add(er);
      } else {
        shellList.add(er);
      }
    }
  }

  void placeFreeHoles(List<EdgeRing> shellList, List<EdgeRing> freeHoleList) {
    for (var hole in freeHoleList) {
      if (hole.getShell() == null) {
        EdgeRing? shell = findEdgeRingContaining(hole, shellList);
        if (shell != null) {
          hole.setShell(shell);
        }
      }
    }
  }

  static EdgeRing? findEdgeRingContaining(EdgeRing testEr, List<EdgeRing> shellList) {
    LinearRing testRing = testEr.getLinearRing()!;
    Envelope testEnv = testRing.getEnvelopeInternal();
    Coordinate? testPt = testRing.getCoordinateN(0);
    EdgeRing? minShell;
    Envelope? minShellEnv;
    for (var tryShell in shellList) {
      LinearRing tryShellRing = tryShell.getLinearRing()!;
      Envelope tryShellEnv = tryShellRing.getEnvelopeInternal();
      if (tryShellEnv.equals(testEnv)) {
        continue;
      }

      if (!tryShellEnv.contains(testEnv)) {
        continue;
      }

      testPt =
          CoordinateArrays.ptNotInList(testRing.getCoordinates(), tryShellRing.getCoordinates());
      bool isContained = false;
      if (PointLocation.isInRing(testPt!, tryShellRing.getCoordinates())) isContained = true;

      if (isContained) {
        if ((minShell == null) || minShellEnv!.contains(tryShellEnv)) {
          minShell = tryShell;
          minShellEnv = minShell.getLinearRing()?.getEnvelopeInternal();
        }
      }
    }
    return minShell;
  }

  List<Polygon> computePolygons(List<EdgeRing> shellList) {
    List<Polygon> resultPolyList = [];
    for (var it in shellList) {
      Polygon poly = it.toPolygon(geometryFactory);
      resultPolyList.add(poly);
    }
    return resultPolyList;
  }
}
