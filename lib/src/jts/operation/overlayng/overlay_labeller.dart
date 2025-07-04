import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';
import 'package:dts/src/jts/util/assert.dart';

import '../overlay/overlay_op.dart';
import 'input_geometry.dart';
import 'overlay_edge.dart';
import 'overlay_graph.dart';
import 'overlay_label.dart';
import 'overlay_ng.dart';

class OverlayLabeller {
  OverlayGraph graph;

  final InputGeometry _inputGeometry;

  late List<OverlayEdge> _edges;

  OverlayLabeller(this.graph, this._inputGeometry) {
    _edges = graph.getEdges();
  }

  void computeLabelling() {
    List<OverlayEdge> nodes = graph.getNodeEdges();
    labelAreaNodeEdges(nodes);
    labelConnectedLinearEdges();
    labelCollapsedEdges();
    labelConnectedLinearEdges();
    labelDisconnectedEdges();
  }

  void labelAreaNodeEdges(List<OverlayEdge> nodes) {
    for (OverlayEdge nodeEdge in nodes) {
      propagateAreaLocations(nodeEdge, 0);
      if (_inputGeometry.hasEdges(1)) {
        propagateAreaLocations(nodeEdge, 1);
      }
    }
  }

  void propagateAreaLocations(OverlayEdge nodeEdge, int geomIndex) {
    if (!_inputGeometry.isArea(geomIndex)) return;

    if (nodeEdge.degree() == 1) return;

    OverlayEdge? eStart = findPropagationStartEdge(nodeEdge, geomIndex);
    if (eStart == null) return;

    int currLoc = eStart.getLocation(geomIndex, Position.left);
    OverlayEdge? e = eStart.oNextOE();
    do {
      OverlayLabel label = e!.getLabel();
      if (!label.isBoundary(geomIndex)) {
        label.setLocationLine(geomIndex, currLoc);
      } else {
        Assert.isTrue(label.hasSides(geomIndex));
        int locRight = e.getLocation(geomIndex, Position.right);
        if (locRight != currLoc) {
          throw TopologyException("side location conflict: arg $geomIndex", e.getCoordinate());
        }
        int locLeft = e.getLocation(geomIndex, Position.left);
        if (locLeft == Location.none) {
          Assert.shouldNeverReachHere("found single null side at  e");
        }
        currLoc = locLeft;
      }
      e = e.oNextOE();
    } while (e != eStart);
  }

  static OverlayEdge? findPropagationStartEdge(OverlayEdge nodeEdge, int geomIndex) {
    OverlayEdge? eStart = nodeEdge;
    do {
      OverlayLabel label = eStart!.getLabel();
      if (label.isBoundary(geomIndex)) {
        Assert.isTrue(label.hasSides(geomIndex));
        return eStart;
      }
      eStart = eStart.oNext() as OverlayEdge?;
    } while (eStart != nodeEdge);
    return null;
  }

  void labelCollapsedEdges() {
    for (OverlayEdge edge in _edges) {
      if (edge.getLabel().isLineLocationUnknown(0)) {
        labelCollapsedEdge(edge, 0);
      }
      if (edge.getLabel().isLineLocationUnknown(1)) {
        labelCollapsedEdge(edge, 1);
      }
    }
  }

  void labelCollapsedEdge(OverlayEdge edge, int geomIndex) {
    OverlayLabel label = edge.getLabel();
    if (!label.isCollapse(geomIndex)) {
      return;
    }

    label.setLocationCollapse(geomIndex);
  }

  void labelConnectedLinearEdges() {
    propagateLinearLocations(0);
    if (_inputGeometry.hasEdges(1)) {
      propagateLinearLocations(1);
    }
  }

  void propagateLinearLocations(int geomIndex) {
    List<OverlayEdge> linearEdges = findLinearEdgesWithLocation(_edges, geomIndex);
    if (linearEdges.size <= 0) {
      return;
    }

    List<OverlayEdge> edgeStack = List.from(linearEdges);
    bool isInputLine = _inputGeometry.isLine(geomIndex);
    while (edgeStack.isNotEmpty) {
      OverlayEdge lineEdge = edgeStack.removeAt(0);
      propagateLinearLocationAtNode(lineEdge, geomIndex, isInputLine, edgeStack);
    }
  }

  static void propagateLinearLocationAtNode(
    OverlayEdge eNode,
    int geomIndex,
    bool isInputLine,
    List<OverlayEdge> edgeStack,
  ) {
    int lineLoc = eNode.getLabel().getLineLocation(geomIndex);
    if (isInputLine && (lineLoc != Location.exterior)) {
      return;
    }

    OverlayEdge? e = eNode.oNextOE();
    do {
      OverlayLabel label = e!.getLabel();
      if (label.isLineLocationUnknown(geomIndex)) {
        label.setLocationLine(geomIndex, lineLoc);
        edgeStack.insert(0, e.symOE());
      }
      e = e.oNextOE();
    } while (e != eNode);
  }

  static List<OverlayEdge> findLinearEdgesWithLocation(List<OverlayEdge> edges, int geomIndex) {
    List<OverlayEdge> linearEdges = [];
    for (OverlayEdge edge in edges) {
      OverlayLabel lbl = edge.getLabel();
      if (lbl.isLinear(geomIndex) && (!lbl.isLineLocationUnknown(geomIndex))) {
        linearEdges.add(edge);
      }
    }
    return linearEdges;
  }

  void labelDisconnectedEdges() {
    for (OverlayEdge edge in _edges) {
      if (edge.getLabel().isLineLocationUnknown(0)) {
        labelDisconnectedEdge(edge, 0);
      }
      if (edge.getLabel().isLineLocationUnknown(1)) {
        labelDisconnectedEdge(edge, 1);
      }
    }
  }

  void labelDisconnectedEdge(OverlayEdge edge, int geomIndex) {
    OverlayLabel label = edge.getLabel();
    if (!_inputGeometry.isArea(geomIndex)) {
      label.setLocationAll(geomIndex, Location.exterior);
      return;
    }
    int edgeLoc = locateEdgeBothEnds(geomIndex, edge);
    label.setLocationAll(geomIndex, edgeLoc);
  }

  int locateEdge(int geomIndex, OverlayEdge edge) {
    int loc = _inputGeometry.locatePointInArea(geomIndex, edge.orig());
    int edgeLoc = (loc != Location.exterior) ? Location.interior : Location.exterior;
    return edgeLoc;
  }

  int locateEdgeBothEnds(int geomIndex, OverlayEdge edge) {
    int locOrig = _inputGeometry.locatePointInArea(geomIndex, edge.orig());
    int locDest = _inputGeometry.locatePointInArea(geomIndex, edge.dest());
    bool isInt = (locOrig != Location.exterior) && (locDest != Location.exterior);
    int edgeLoc = (isInt) ? Location.interior : Location.exterior;
    return edgeLoc;
  }

  void markResultAreaEdges(OverlayOpCode overlayOpCode) {
    for (OverlayEdge edge in _edges) {
      markInResultArea(edge, overlayOpCode);
    }
  }

  void markInResultArea(OverlayEdge e, OverlayOpCode overlayOpCode) {
    OverlayLabel label = e.getLabel();
    if (label.isBoundaryEither() &&
        OverlayNG.isResultOfOp(
          overlayOpCode,
          label.getLocationBoundaryOrLine(0, Position.right, e.isForward()),
          label.getLocationBoundaryOrLine(1, Position.right, e.isForward()),
        )) {
      e.markInResultArea();
    }
  }

  void unmarkDuplicateEdgesFromResultArea() {
    for (OverlayEdge edge in _edges) {
      if (edge.isInResultAreaBoth()) {
        edge.unmarkFromResultAreaBoth();
      }
    }
  }
}
