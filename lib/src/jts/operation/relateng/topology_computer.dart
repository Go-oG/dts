import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/polygon_node_topology.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/position.dart';

import 'node_section.dart';
import 'node_sections.dart';
import 'relate_edge.dart';
import 'relate_geometry.dart';
import 'relate_node.dart';
import 'topology_predicate.dart';

class TopologyComputer {
  final TopologyPredicate _predicate;
  RelateGeometry geomA;
  final RelateGeometry _geomB;

  final Map<Coordinate, NodeSections> _nodeMap = {};

  TopologyComputer(this._predicate, this.geomA, this._geomB) {
    initExteriorDims();
  }

  void initExteriorDims() {
    int dimRealA = geomA.getDimensionReal();
    int dimRealB = _geomB.getDimensionReal();
    if ((dimRealA == Dimension.P) && (dimRealB == Dimension.L)) {
      updateDim(Location.exterior, Location.interior, Dimension.L);
    } else if ((dimRealA == Dimension.L) && (dimRealB == Dimension.P)) {
      updateDim(Location.interior, Location.exterior, Dimension.L);
    } else if ((dimRealA == Dimension.P) && (dimRealB == Dimension.A)) {
      updateDim(Location.exterior, Location.interior, Dimension.A);
      updateDim(Location.exterior, Location.boundary, Dimension.L);
    } else if ((dimRealA == Dimension.A) && (dimRealB == Dimension.P)) {
      updateDim(Location.interior, Location.exterior, Dimension.A);
      updateDim(Location.boundary, Location.exterior, Dimension.L);
    } else if ((dimRealA == Dimension.L) && (dimRealB == Dimension.A)) {
      updateDim(Location.exterior, Location.interior, Dimension.A);
    } else if ((dimRealA == Dimension.A) && (dimRealB == Dimension.L)) {
      updateDim(Location.interior, Location.exterior, Dimension.A);
    } else if ((dimRealA == Dimension.False) || (dimRealB == Dimension.False)) {
      if (dimRealA != Dimension.False) {
        initExteriorEmpty(RelateGeometry.GEOM_A);
      }
      if (dimRealB != Dimension.False) {
        initExteriorEmpty(RelateGeometry.GEOM_B);
      }
    }
  }

  void initExteriorEmpty(bool geomNonEmpty) {
    int dimNonEmpty = getDimension(geomNonEmpty);
    switch (dimNonEmpty) {
      case Dimension.P:
        updateDim2(geomNonEmpty, Location.interior, Location.exterior, Dimension.P);
        break;
      case Dimension.L:
        if (getGeometry(geomNonEmpty).hasBoundary()) {
          updateDim2(geomNonEmpty, Location.boundary, Location.exterior, Dimension.P);
        }
        updateDim2(geomNonEmpty, Location.interior, Location.exterior, Dimension.L);
        break;
      case Dimension.A:
        updateDim2(geomNonEmpty, Location.boundary, Location.exterior, Dimension.L);
        updateDim2(geomNonEmpty, Location.interior, Location.exterior, Dimension.A);
        break;
    }
  }

  RelateGeometry getGeometry(bool isA) {
    return isA ? geomA : _geomB;
  }

  int getDimension(bool isA) {
    return getGeometry(isA).getDimension();
  }

  bool isAreaArea() {
    return (getDimension(RelateGeometry.GEOM_A) == Dimension.A) && (getDimension(RelateGeometry.GEOM_B) == Dimension.A);
  }

  bool isSelfNodingRequired() {
    if (!_predicate.requireSelfNoding()) {
      return false;
    }

    if (geomA.isSelfNodingRequired()) {
      return true;
    }

    if (_geomB.hasAreaAndLine()) {
      return true;
    }

    return false;
  }

  bool isExteriorCheckRequired(bool isA) {
    return _predicate.requireExteriorCheck(isA);
  }

  void updateDim(int locA, int locB, int dimension) {
    _predicate.updateDimension(locA, locB, dimension);
  }

  void updateDim2(bool isAB, int loc1, int loc2, int dimension) {
    if (isAB) {
      updateDim(loc1, loc2, dimension);
    } else {
      updateDim(loc2, loc1, dimension);
    }
  }

  bool isResultKnown() {
    return _predicate.isKnown();
  }

  bool getResult() {
    return _predicate.value();
  }

  void finish() {
    _predicate.finish();
  }

  NodeSections getNodeSections(Coordinate nodePt) {
    NodeSections? node = _nodeMap[nodePt];
    if (node == null) {
      node = NodeSections(nodePt);
      _nodeMap.put(nodePt, node);
    }
    return node;
  }

  void addIntersection(NodeSection a, NodeSection b) {
    if (!a.isSameGeometry(b)) {
      updateIntersectionAB(a, b);
    }
    addNodeSections(a, b);
  }

  void updateIntersectionAB(NodeSection a, NodeSection b) {
    if (NodeSection.isAreaArea(a, b)) {
      updateAreaAreaCross(a, b);
    }
    updateNodeLocation(a, b);
  }

  void updateAreaAreaCross(NodeSection a, NodeSection b) {
    bool isProper = NodeSection.isProper2(a, b);
    if (isProper ||
        PolygonNodeTopology.isCrossing(
            a.nodePt(), a.getVertex(0)!, a.getVertex(1)!, b.getVertex(0)!, b.getVertex(1)!)) {
      updateDim(Location.interior, Location.interior, Dimension.A);
    }
  }

  void updateNodeLocation(NodeSection a, NodeSection b) {
    Coordinate pt = a.nodePt();
    int locA = geomA.locateNode(pt, a.getPolygonal());
    int locB = _geomB.locateNode(pt, b.getPolygonal());
    updateDim(locA, locB, Dimension.P);
  }

  void addNodeSections(NodeSection ns0, NodeSection ns1) {
    final sections = getNodeSections(ns0.nodePt());
    sections.addNodeSection(ns0);
    sections.addNodeSection(ns1);
  }

  void addPointOnPointInterior(Coordinate pt) {
    updateDim(Location.interior, Location.interior, Dimension.P);
  }

  void addPointOnPointExterior(bool isGeomA, Coordinate? pt) {
    updateDim2(isGeomA, Location.interior, Location.exterior, Dimension.P);
  }

  void addPointOnGeometry(bool isPointA, int locTarget, int dimTarget, Coordinate pt) {
    updateDim2(isPointA, Location.interior, locTarget, Dimension.P);
    if (getGeometry(!isPointA).isEmpty()) {
      return;
    }

    switch (dimTarget) {
      case Dimension.P:
        return;
      case Dimension.L:
        return;
      case Dimension.A:
        updateDim2(isPointA, Location.exterior, Location.interior, Dimension.A);
        updateDim2(isPointA, Location.exterior, Location.boundary, Dimension.L);
        return;
    }
    throw ("Unknown target dimension: $dimTarget");
  }

  void addLineEndOnGeometry(bool isLineA, int locLineEnd, int locTarget, int dimTarget, Coordinate? pt) {
    updateDim2(isLineA, locLineEnd, locTarget, Dimension.P);
    if (getGeometry(!isLineA).isEmpty()) {
      return;
    }

    switch (dimTarget) {
      case Dimension.P:
        return;
      case Dimension.L:
        addLineEndOnLine(isLineA, locLineEnd, locTarget, pt);
        return;
      case Dimension.A:
        addLineEndOnArea(isLineA, locLineEnd, locTarget, pt);
        return;
    }
    throw ("Unknown target dimension:$dimTarget");
  }

  void addLineEndOnLine(bool isLineA, int locLineEnd, int locLine, Coordinate? pt) {
    if (locLine == Location.exterior) {
      updateDim2(isLineA, Location.interior, Location.exterior, Dimension.L);
    }
  }

  void addLineEndOnArea(bool isLineA, int locLineEnd, int locArea, Coordinate? pt) {
    if (locArea != Location.boundary) {
      updateDim2(isLineA, Location.interior, locArea, Dimension.L);
      updateDim2(isLineA, Location.exterior, locArea, Dimension.A);
    }
  }

  void addAreaVertex(bool isAreaA, int locArea, int locTarget, int dimTarget, Coordinate? pt) {
    if (locTarget == Location.exterior) {
      updateDim2(isAreaA, Location.interior, Location.exterior, Dimension.A);
      if (locArea == Location.boundary) {
        updateDim2(isAreaA, Location.boundary, Location.exterior, Dimension.L);
        updateDim2(isAreaA, Location.exterior, Location.exterior, Dimension.A);
      }
      return;
    }
    switch (dimTarget) {
      case Dimension.P:
        addAreaVertexOnPoint(isAreaA, locArea, pt);
        return;
      case Dimension.L:
        addAreaVertexOnLine(isAreaA, locArea, locTarget, pt);
        return;
      case Dimension.A:
        addAreaVertexOnArea(isAreaA, locArea, locTarget, pt);
        return;
    }
    throw ("Unknown target dimension: $dimTarget");
  }

  void addAreaVertexOnPoint(bool isAreaA, int locArea, Coordinate? pt) {
    updateDim2(isAreaA, locArea, Location.interior, Dimension.P);
    updateDim2(isAreaA, Location.interior, Location.exterior, Dimension.A);
    if (locArea == Location.boundary) {
      updateDim2(isAreaA, Location.boundary, Location.exterior, Dimension.L);
      updateDim2(isAreaA, Location.exterior, Location.exterior, Dimension.A);
    }
  }

  void addAreaVertexOnLine(bool isAreaA, int locArea, int locTarget, Coordinate? pt) {
    updateDim2(isAreaA, locArea, locTarget, Dimension.P);
    if (locArea == Location.interior) {
      updateDim2(isAreaA, Location.interior, Location.exterior, Dimension.A);
    }
  }

  void addAreaVertexOnArea(bool isAreaA, int locArea, int locTarget, Coordinate? pt) {
    if (locTarget == Location.boundary) {
      if (locArea == Location.boundary) {
        updateDim2(isAreaA, Location.boundary, Location.boundary, Dimension.P);
      } else {
        updateDim2(isAreaA, Location.interior, Location.interior, Dimension.A);
        updateDim2(isAreaA, Location.interior, Location.boundary, Dimension.L);
        updateDim2(isAreaA, Location.interior, Location.exterior, Dimension.A);
      }
    } else {
      updateDim2(isAreaA, Location.interior, locTarget, Dimension.A);
      if (locArea == Location.boundary) {
        updateDim2(isAreaA, Location.boundary, locTarget, Dimension.L);
        updateDim2(isAreaA, Location.exterior, locTarget, Dimension.A);
      }
    }
  }

  void evaluateNodes() {
    for (NodeSections nodeSections in _nodeMap.values) {
      if (nodeSections.hasInteractionAB()) {
        evaluateNode(nodeSections);
        if (isResultKnown()) {
          return;
        }
      }
    }
  }

  void evaluateNode(NodeSections nodeSections) {
    Coordinate p = nodeSections.getCoordinate();
    RelateNGNode node = nodeSections.createNode();
    bool isAreaInteriorA = geomA.isNodeInArea(p, nodeSections.getPolygonal(RelateGeometry.GEOM_A));
    bool isAreaInteriorB = _geomB.isNodeInArea(p, nodeSections.getPolygonal(RelateGeometry.GEOM_B));
    node.finish(isAreaInteriorA, isAreaInteriorB);
    evaluateNodeEdges(node);
  }

  void evaluateNodeEdges(RelateNGNode node) {
    for (RelateEdge e in node.getEdges()) {
      if (isAreaArea()) {
        updateDim(
          e.location(RelateGeometry.GEOM_A, Position.left),
          e.location(RelateGeometry.GEOM_B, Position.left),
          Dimension.A,
        );
        updateDim(
          e.location(RelateGeometry.GEOM_A, Position.right),
          e.location(RelateGeometry.GEOM_B, Position.right),
          Dimension.A,
        );
      }
      updateDim(
        e.location(RelateGeometry.GEOM_A, Position.on),
        e.location(RelateGeometry.GEOM_B, Position.on),
        Dimension.L,
      );
    }
  }
}
