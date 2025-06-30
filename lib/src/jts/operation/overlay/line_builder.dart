import 'package:dts/src/jts/algorithm/point_locator.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/label.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'overlay_op.dart';

class LineBuilder {
  final OverlayOp _op;

  GeomFactory geometryFactory;

  final PointLocator _ptLocator;

  final List<Edge> _lineEdgesList = [];

  final List<LineString> _resultLineList = [];

  LineBuilder(this._op, this.geometryFactory, this._ptLocator);

  List<LineString> build(OverlayOpCode opCode) {
    findCoveredLineEdges();
    collectLines(opCode);
    buildLines(opCode);
    return _resultLineList;
  }

  void findCoveredLineEdges() {
    for (var node in _op.getGraph().getNodes()) {
      (node.getEdges() as DirectedEdgeStar).findCoveredLineEdges();
    }
    for (var it in _op.getGraph().getEdgeEnds()) {
      DirectedEdge de = it as DirectedEdge;
      Edge e = de.getEdge();
      if (de.isLineEdge() && (!e.isCoveredSet())) {
        bool isCovered = _op.isCoveredByA(de.getCoordinate());
        e.setCovered(isCovered);
      }
    }
  }

  void collectLines(OverlayOpCode opCode) {
    for (var it in _op.getGraph().getEdgeEnds()) {
      DirectedEdge de = it as DirectedEdge;
      collectLineEdge(de, opCode, _lineEdgesList);
      collectBoundaryTouchEdge(de, opCode, _lineEdgesList);
    }
  }

  void collectLineEdge(DirectedEdge de, OverlayOpCode opCode, List edges) {
    Label label = de.getLabel()!;
    Edge e = de.getEdge();
    if (de.isLineEdge()) {
      if (((!de.isVisited()) && OverlayOp.isResultOfOp(label, opCode)) && (!e.isCovered())) {
        edges.add(e);
        de.setVisitedEdge(true);
      }
    }
  }

  void collectBoundaryTouchEdge(DirectedEdge de, OverlayOpCode opCode, List edges) {
    Label label = de.getLabel()!;
    if (de.isLineEdge()) return;

    if (de.isVisited()) return;

    if (de.isInteriorAreaEdge()) return;

    if (de.getEdge().isInResult) return;

    Assert.isTrue((!(de.isInResult() || de.getSym().isInResult())) || (!de.getEdge().isInResult));
    if (OverlayOp.isResultOfOp(label, opCode) && (opCode == OverlayOpCode.intersection)) {
      edges.add(de.getEdge());
      de.setVisitedEdge(true);
    }
  }

  void buildLines(OverlayOpCode opCode) {
    for (var e in _lineEdgesList) {
      LineString line = geometryFactory.createLineString2(e.getCoordinates());
      _resultLineList.add(line);
      e.isInResult = true;
    }
  }

  void labelIsolatedLines(List<Edge> edgesList) {
    for (var e in edgesList) {
      Label label = e.getLabel()!;
      if (e.isIsolated()) {
        if (label.isNull(0)) {
          labelIsolatedLine(e, 0);
        } else {
          labelIsolatedLine(e, 1);
        }
      }
    }
  }

  void labelIsolatedLine(Edge e, int targetIndex) {
    int loc = _ptLocator.locate(e.getCoordinate()!, _op.getArgGeometry(targetIndex)!);
    e.getLabel()!.setLocation(targetIndex, loc);
  }
}
