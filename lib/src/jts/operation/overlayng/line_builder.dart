 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/location.dart';

import '../overlay/overlay_op.dart';
import 'input_geometry.dart';
import 'overlay_edge.dart';
import 'overlay_graph.dart';
import 'overlay_label.dart';
import 'overlay_ng.dart';

class NgLineBuilder {
  GeomFactory geometryFactory;
  OverlayGraph graph;

  final OverlayOpCode _opCode;
  final bool _hasResultArea;
  late int _inputAreaIndex;

  bool _isAllowMixedResult = !OverlayNG.strictModeDefault;

  bool isAllowCollapseLines = !OverlayNG.strictModeDefault;

  final List<LineString> _lines = [];

  NgLineBuilder(InputGeometry inputGeom, this.graph, this._hasResultArea, this._opCode, this.geometryFactory) {
    _inputAreaIndex = inputGeom.getAreaIndex();
  }

  void setStrictMode(bool isStrictResultMode) {
    isAllowCollapseLines = !isStrictResultMode;
    _isAllowMixedResult = !isStrictResultMode;
  }

  List<LineString> getLines() {
    markResultLines();
    addResultLines();
    return _lines;
  }

  void markResultLines() {
    List<OverlayEdge> edges = graph.getEdges();
    for (OverlayEdge edge in edges) {
      if (edge.isInResultEither()) {
        continue;
      }

      if (isResultLine(edge.getLabel())) {
        edge.markInResultLine();
      }
    }
  }

  bool isResultLine(OverlayLabel lbl) {
    if (lbl.isBoundarySingleton()) {
      return false;
    }

    if ((!isAllowCollapseLines) && lbl.isBoundaryCollapse()) {
      return false;
    }

    if (lbl.isInteriorCollapse()) {
      return false;
    }

    if (_opCode != OverlayOpCode.intersection) {
      if (lbl.isCollapseAndNotPartInterior()) {
        return false;
      }

      if (_hasResultArea && lbl.isLineInArea(_inputAreaIndex)) {
        return false;
      }
    }
    if ((_isAllowMixedResult && (_opCode == OverlayOpCode.intersection)) && lbl.isBoundaryTouch()) {
      return true;
    }
    int aLoc = effectiveLocation(lbl, 0);
    int bLoc = effectiveLocation(lbl, 1);
    bool isInResult = OverlayNG.isResultOfOp(_opCode, aLoc, bLoc);
    return isInResult;
  }

  static int effectiveLocation(OverlayLabel lbl, int geomIndex) {
    if (lbl.isCollapse(geomIndex)) {
      return Location.interior;
    }

    if (lbl.isLine2(geomIndex)) {
      return Location.interior;
    }

    return lbl.getLineLocation(geomIndex);
  }

  void addResultLines() {
    List<OverlayEdge> edges = graph.getEdges();
    for (OverlayEdge edge in edges) {
      if (!edge.isInResultLine()) {
        continue;
      }

      if (edge.isVisited) {
        continue;
      }

      _lines.add(toLine(edge));
      edge.markVisitedBoth();
    }
  }

  LineString toLine(OverlayEdge edge) {
    bool isForward = edge.isForward();
    CoordinateList pts = CoordinateList();
    pts.add3(edge.orig(), false);
    edge.addCoordinates(pts);
    Array<Coordinate> ptsOut = pts.toCoordinateArray2(isForward);
    LineString line = geometryFactory.createLineString2(ptsOut);
    return line;
  }

  void addResultLinesMerged() {
    addResultLinesForNodes();
    addResultLinesRings();
  }

  void addResultLinesForNodes() {
    List<OverlayEdge> edges = graph.getEdges();
    for (OverlayEdge edge in edges) {
      if (!edge.isInResultLine()) {
        continue;
      }

      if (edge.isVisited) {
        continue;
      }

      if (degreeOfLines(edge) != 2) {
        _lines.add(buildLine(edge));
      }
    }
  }

  void addResultLinesRings() {
    List<OverlayEdge> edges = graph.getEdges();
    for (OverlayEdge edge in edges) {
      if (!edge.isInResultLine()) {
        continue;
      }

      if (edge.isVisited) {
        continue;
      }

      _lines.add(buildLine(edge));
    }
  }

  LineString buildLine(OverlayEdge node) {
    CoordinateList pts = CoordinateList();
    pts.add3(node.orig(), false);
    bool isForward = node.isForward();
    OverlayEdge? e = node;
    do {
      e!.markVisitedBoth();
      e.addCoordinates(pts);
      if (degreeOfLines(e.symOE()) != 2) {
        break;
      }
      e = nextLineEdgeUnvisited(e.symOE());
    } while (e != null);
    Array<Coordinate> ptsOut = pts.toCoordinateArray2(isForward);
    LineString line = geometryFactory.createLineString2(ptsOut);
    return line;
  }

  static OverlayEdge? nextLineEdgeUnvisited(OverlayEdge node) {
    OverlayEdge? e = node;
    do {
      e = e!.oNextOE();
      if (e!.isVisited) {
        continue;
      }

      if (e.isInResultLine()) {
        return e;
      }
    } while (e != node);
    return null;
  }

  static int degreeOfLines(OverlayEdge node) {
    int degree = 0;
    OverlayEdge? e = node;
    do {
      if (e!.isInResultLine()) {
        degree++;
      }
      e = e.oNextOE();
    } while (e != node);
    return degree;
  }
}
