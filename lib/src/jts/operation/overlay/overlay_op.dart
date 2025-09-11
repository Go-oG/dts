import 'dart:math';

import 'package:dts/src/jts/algorithm/point_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geomgraph/depth.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/edge_noding_validator.dart';
import 'package:dts/src/jts/geomgraph/label.dart';
import 'package:dts/src/jts/geomgraph/node.dart';
import 'package:dts/src/jts/geomgraph/planar_graph.dart';
import 'package:dts/src/jts/operation/geometry_graph_operation.dart';
import 'package:dts/src/jts/util/assert.dart';

import '../../geom/polygon.dart';
import '../overlay/polygon_builder.dart';
import 'line_builder.dart';
import 'overlay_node_factory.dart';
import 'point_builder.dart';

enum OverlayOpCode {
  intersection(1),
  union(2),
  difference(3),
  symDifference(4);

  //code
  final int c;

  const OverlayOpCode(this.c);
}

class OverlayOp extends GeometryGraphOperation {
  static Geometry overlayOp(Geometry geom0, Geometry geom1, OverlayOpCode opCode) {
    return OverlayOp(geom0, geom1).getResultGeometry(opCode);
  }

  static bool isResultOfOp(Label label, OverlayOpCode opCode) {
    int loc0 = label.getLocation(0);
    int loc1 = label.getLocation(1);
    return isResultOfOp2(loc0, loc1, opCode);
  }

  static bool isResultOfOp2(int loc0, int loc1, OverlayOpCode overlayOpCode) {
    if (loc0 == Location.boundary) loc0 = Location.interior;

    if (loc1 == Location.boundary) loc1 = Location.interior;

    switch (overlayOpCode) {
      case OverlayOpCode.intersection:
        return (loc0 == Location.interior) && (loc1 == Location.interior);
      case OverlayOpCode.union:
        return (loc0 == Location.interior) || (loc1 == Location.interior);
      case OverlayOpCode.difference:
        return (loc0 == Location.interior) && (loc1 != Location.interior);
      case OverlayOpCode.symDifference:
        return (loc0 == Location.interior && loc1 != Location.interior) ||
            (loc0 != Location.interior && loc1 == Location.interior);
    }
  }

  final ptLocator = PointLocator.empty();

  late PGPlanarGraph graph;
  late GeometryFactory geomFact;

  Geometry? _resultGeom;

  EdgeList edgeList = EdgeList();

  List<Polygon> _resultPolyList = [];

  List<LineString> resultLineList = [];

  List<Point> _resultPointList = [];

  OverlayOp(Geometry g0, Geometry g1) : super(g0, g1) {
    graph = PGPlanarGraph(OverlayNodeFactory());
    geomFact = g0.factory;
  }

  Geometry getResultGeometry(OverlayOpCode overlayOpCode) {
    computeOverlay(overlayOpCode);
    return _resultGeom!;
  }

  PGPlanarGraph getGraph() {
    return graph;
  }

  void computeOverlay(OverlayOpCode opCode) {
    copyPoints(0);
    copyPoints(1);
    arg[0].computeSelfNodes(li, false);
    arg[1].computeSelfNodes(li, false);
    arg[0].computeEdgeIntersections(arg[1], li, true);
    List<Edge> baseSplitEdges = [];
    arg[0].computeSplitEdges(baseSplitEdges);
    arg[1].computeSplitEdges(baseSplitEdges);

    insertUniqueEdges(baseSplitEdges);
    computeLabelsFromDepths();
    replaceCollapsedEdges();
    EdgeNodingValidator.checkValid2(edgeList.getEdges());
    graph.addEdges(edgeList.getEdges());
    computeLabelling();
    labelIncompleteNodes();
    findResultAreaEdges(opCode);
    cancelDuplicateResultEdges();
    final polyBuilder = OPolygonBuilder(geomFact);
    polyBuilder.add(graph);
    _resultPolyList = polyBuilder.getPolygons();
    final lineBuilder = LineBuilder(this, geomFact, ptLocator);
    resultLineList = lineBuilder.build(opCode);

    final pointBuilder = PointBuilder(this, geomFact, ptLocator);
    _resultPointList = pointBuilder.build(opCode);
    _resultGeom = computeGeometry(_resultPointList, resultLineList, _resultPolyList, opCode);
  }

  void insertUniqueEdges(List<Edge> edges) {
    for (var e in edges) {
      insertUniqueEdge(e);
    }
  }

  void insertUniqueEdge(Edge e) {
    Edge? existingEdge = edgeList.findEqualEdge(e);
    if (existingEdge != null) {
      Label existingLabel = existingEdge.getLabel()!;
      Label labelToMerge = e.getLabel()!;
      if (!existingEdge.isPointwiseEqual(e)) {
        labelToMerge = Label(e.getLabel()!);
        labelToMerge.flip();
      }
      Depth depth = existingEdge.getDepth();
      if (depth.isNull()) {
        depth.addLabel(existingLabel);
      }
      depth.addLabel(labelToMerge);
      existingLabel.merge(labelToMerge);
    } else {
      edgeList.add(e);
    }
  }

  void computeLabelsFromDepths() {
    for (var it = edgeList.iterator(); it.hasNext();) {
      Edge e = it.next();
      Label lbl = e.getLabel()!;
      Depth depth = e.getDepth();
      if (!depth.isNull()) {
        depth.normalize();
        for (int i = 0; i < 2; i++) {
          if (((!lbl.isNull(i)) && lbl.isArea()) && (!depth.isNull2(i))) {
            if (depth.getDelta(i) == 0) {
              lbl.toLine(i);
            } else {
              Assert.isTrue(!depth.isNull3(i, Position.left), "depth of LEFT side has not been initialized");
              lbl.setLocation2(i, Position.left, depth.getLocation(i, Position.left));
              Assert.isTrue(!depth.isNull3(i, Position.right), "depth of RIGHT side has not been initialized");
              lbl.setLocation2(i, Position.right, depth.getLocation(i, Position.right));
            }
          }
        }
      }
    }
  }

  void replaceCollapsedEdges() {
    List<Edge> newEdges = [];
    for (var it = edgeList.iterator(); it.hasNext();) {
      Edge e = it.next();
      if (e.isCollapsed()) {
        it.remove();
        newEdges.add(e.getCollapsedEdge());
      }
    }
    edgeList.addAll(newEdges);
  }

  void copyPoints(int argIndex) {
    for (var graphNode in arg[argIndex].getNodeIterator()) {
      Node newNode = graph.addNode(graphNode.getCoordinate());
      newNode.setLabel2(argIndex, graphNode.getLabel()!.getLocation(argIndex));
    }
  }

  void computeLabelling() {
    for (var node in graph.getNodes()) {
      node.getEdges()!.computeLabelling(arg);
    }
    mergeSymLabels();
    updateNodeLabelling();
  }

  void mergeSymLabels() {
    for (var node in graph.getNodes()) {
      (node.getEdges() as DirectedEdgeStar).mergeSymLabels();
    }
  }

  void updateNodeLabelling() {
    for (var node in graph.getNodes()) {
      Label lbl = (node.getEdges() as DirectedEdgeStar).getLabel()!;
      node.getLabel()!.merge(lbl);
    }
  }

  void labelIncompleteNodes() {
    for (var n in graph.getNodes()) {
      Label label = n.getLabel()!;
      if (n.isIsolated()) {
        if (label.isNull(0)) {
          labelIncompleteNode(n, 0);
        } else {
          labelIncompleteNode(n, 1);
        }
      }
      (n.getEdges() as DirectedEdgeStar).updateLabelling(label);
    }
  }

  void labelIncompleteNode(Node n, int targetIndex) {
    int loc = ptLocator.locate(n.getCoordinate(), arg[targetIndex].getGeometry()!);
    n.getLabel()!.setLocation(targetIndex, loc);
  }

  void findResultAreaEdges(OverlayOpCode opCode) {
    for (var it in graph.getEdgeEnds()) {
      DirectedEdge de = it as DirectedEdge;
      Label label = de.getLabel()!;
      if ((label.isArea() && (!de.isInteriorAreaEdge())) &&
          isResultOfOp2(label.getLocation2(0, Position.right), label.getLocation2(1, Position.right), opCode)) {
        de.setInResult(true);
      }
    }
  }

  void cancelDuplicateResultEdges() {
    for (var it in graph.getEdgeEnds()) {
      DirectedEdge de = it as DirectedEdge;
      DirectedEdge sym = de.getSym();
      if (de.isInResult() && sym.isInResult()) {
        de.setInResult(false);
        sym.setInResult(false);
      }
    }
  }

  bool isCoveredByLA(Coordinate coord) {
    if (isCovered(coord, resultLineList)) return true;

    if (isCovered(coord, _resultPolyList)) return true;

    return false;
  }

  bool isCoveredByA(Coordinate coord) {
    if (isCovered(coord, _resultPolyList)) return true;

    return false;
  }

  bool isCovered(Coordinate coord, List<Geometry> geomList) {
    for (var it in geomList) {
      int loc = ptLocator.locate(coord, it);
      if (loc != Location.exterior) return true;
    }
    return false;
  }

  Geometry computeGeometry(
    List<Point> resultPointList,
    List<LineString> resultLineList,
    List<Polygon> resultPolyList,
    OverlayOpCode opcode,
  ) {
    List<Geometry> geomList = [];
    geomList.addAll(resultPointList);
    geomList.addAll(resultLineList);
    geomList.addAll(resultPolyList);
    if (geomList.isEmpty) {
      return createEmptyResult(opcode, arg[0].getGeometry()!, arg[1].getGeometry()!, geomFact);
    }
    return geomFact.buildGeometry(geomList);
  }

  static Geometry createEmptyResult(OverlayOpCode overlayOpCode, Geometry a, Geometry b, GeometryFactory geomFact) {
    int resultDim = resultDimension(overlayOpCode, a, b);
    return geomFact.createEmpty(resultDim);
  }

  static int resultDimension(OverlayOpCode opCode, Geometry g0, Geometry g1) {
    int dim0 = g0.getDimension();
    int dim1 = g1.getDimension();
    int resultDimension = -1;
    switch (opCode) {
      case OverlayOpCode.intersection:
        resultDimension = min(dim0, dim1);
        break;
      case OverlayOpCode.union:
        resultDimension = max(dim0, dim1);
        break;
      case OverlayOpCode.difference:
        resultDimension = dim0;
        break;
      case OverlayOpCode.symDifference:
        resultDimension = max(dim0, dim1);
        break;
    }
    return resultDimension;
  }
}
