import 'package:dts/src/jts/algorithm/point_location.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/edge_ring.dart';
import 'package:dts/src/jts/geomgraph/planar_graph.dart';
import 'package:dts/src/jts/util/assert.dart';

import '../../geomgraph/node.dart';
import 'maximal_edge_ring.dart';
import 'minimal_edge_ring.dart';

class OPolygonBuilder {
  GeometryFactory geometryFactory;

  List<EdgeRing> shellList = [];

  OPolygonBuilder(this.geometryFactory);

  void add(PGPlanarGraph graph) {
    addAll(graph.getEdgeEnds().cast(), graph.getNodes());
  }

  void addAll(List<DirectedEdge> dirEdges, Iterable<Node> nodes) {
    PGPlanarGraph.linkResultDirectedEdges2(nodes);
    List<OMaximalEdgeRing> maxEdgeRings = buildMaximalEdgeRings(dirEdges);
    List<EdgeRing> freeHoleList = [];
    final edgeRings = buildMinimalEdgeRings(maxEdgeRings, shellList, freeHoleList);
    sortShellsAndHoles(edgeRings, shellList, freeHoleList);
    placeFreeHoles(shellList, freeHoleList);
  }

  List<Polygon> getPolygons() {
    return computePolygons(shellList);
  }

  List<OMaximalEdgeRing> buildMaximalEdgeRings(List<DirectedEdge> dirEdges) {
    List<OMaximalEdgeRing> maxEdgeRings = [];
    for (var de in dirEdges) {
      if (de.isInResult() && de.getLabel()!.isArea()) {
        if (de.getEdgeRing() == null) {
          final er = OMaximalEdgeRing(de, geometryFactory);
          maxEdgeRings.add(er);
          er.setInResult();
        }
      }
    }
    return maxEdgeRings;
  }

  List<EdgeRing> buildMinimalEdgeRings(
      List<OMaximalEdgeRing> maxEdgeRings, List shellList, List freeHoleList) {
    List<EdgeRing> edgeRings = [];
    for (var er in maxEdgeRings) {
      if (er.getMaxNodeDegree() > 2) {
        er.linkDirectedEdgesForMinimalEdgeRings();
        final minEdgeRings = er.buildMinimalRings();
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

  EdgeRing? findShell(List<OMinimalEdgeRing> minEdgeRings) {
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

  void placePolygonHoles(EdgeRing shell, List<OMinimalEdgeRing> minEdgeRings) {
    for (var er in minEdgeRings) {
      if (er.isHole()) {
        er.setShell(shell);
      }
    }
  }

  void sortShellsAndHoles(List<EdgeRing> edgeRings, List shellList, List freeHoleList) {
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
        if (shell == null)
          throw TopologyException("unable to assign hole to a shell", hole.getCoordinate(0));

        hole.setShell(shell);
      }
    }
  }

  static EdgeRing? findEdgeRingContaining(EdgeRing testEr, List<EdgeRing> shellList) {
    final testRing = testEr.getLinearRing()!;

    Envelope testEnv = testRing.getEnvelopeInternal();
    Coordinate testPt = testRing.getCoordinateN(0);
    EdgeRing? minShell;
    Envelope? minShellEnv;
    for (var tryShell in shellList) {
      LinearRing tryShellRing = tryShell.getLinearRing()!;
      Envelope tryShellEnv = tryShellRing.getEnvelopeInternal();
      if (tryShellEnv.equals(testEnv)) continue;

      if (!tryShellEnv.contains(testEnv)) continue;

      testPt =
          CoordinateArrays.ptNotInList(testRing.getCoordinates(), tryShellRing.getCoordinates())!;
      bool isContained = false;
      if (PointLocation.isInRing(testPt, tryShellRing.getCoordinates())) isContained = true;

      if (isContained) {
        if ((minShell == null) || minShellEnv!.contains(tryShellEnv)) {
          minShell = tryShell;
          minShellEnv = minShell.getLinearRing()!.getEnvelopeInternal();
        }
      }
    }
    return minShell;
  }

  List<Polygon> computePolygons(List<EdgeRing> shellList) {
    return shellList.map((e) => e.toPolygon(geometryFactory)).toList();
  }
}
