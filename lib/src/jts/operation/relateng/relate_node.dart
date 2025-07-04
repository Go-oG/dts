 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/position.dart';

import 'node_section.dart';
import 'relate_edge.dart';
import 'relate_geometry.dart';

class RelateNGNode {
  final Coordinate nodePt;

  final List<RelateEdge> _edges = [];

  RelateNGNode(this.nodePt);

  Coordinate getCoordinate()=>nodePt;

  List<RelateEdge> getEdges()=>_edges;

  void addEdges2(List<NodeSection> nss) {
    for (NodeSection ns in nss) {
      addEdges(ns);
    }
  }

  void addEdges(NodeSection ns) {
    switch (ns.dimension()) {
      case Dimension.L:
        addLineEdge(ns.isA(), ns.getVertex(0));
        addLineEdge(ns.isA(), ns.getVertex(1));
        break;
      case Dimension.A:
        final e0 = addAreaEdge(ns.isA(), ns.getVertex(0), false)!;
        final e1 = addAreaEdge(ns.isA(), ns.getVertex(1), true)!;
        int index0 = _edges.indexOf(e0);
        int index1 = _edges.indexOf(e1);
        updateEdgesInArea(ns.isA(), index0, index1);
        updateIfAreaPrev(ns.isA(), index0);
        updateIfAreaNext(ns.isA(), index1);
        break;
    }
  }

  void updateEdgesInArea(bool isA, int indexFrom, int indexTo) {
    int index = nextIndex(_edges, indexFrom);
    while (index != indexTo) {
      RelateEdge edge = _edges.get(index);
      edge.setAreaInterior(isA);
      index = nextIndex(_edges, index);
    }
  }

  void updateIfAreaPrev(bool isA, int index) {
    int indexPrev = prevIndex(_edges, index);
    RelateEdge edgePrev = _edges.get(indexPrev);
    if (edgePrev.isInterior(isA, Position.left)) {
      RelateEdge edge = _edges.get(index);
      edge.setAreaInterior(isA);
    }
  }

  void updateIfAreaNext(bool isA, int index) {
    int indexNext = nextIndex(_edges, index);
    RelateEdge edgeNext = _edges.get(indexNext);
    if (edgeNext.isInterior(isA, Position.right)) {
      RelateEdge edge = _edges.get(index);
      edge.setAreaInterior(isA);
    }
  }

  RelateEdge? addLineEdge(bool isA, Coordinate? dirPt) {
    return addEdge(isA, dirPt, Dimension.L, false);
  }

  RelateEdge? addAreaEdge(bool isA, Coordinate? dirPt, bool isForward) {
    return addEdge(isA, dirPt, Dimension.A, isForward);
  }

  RelateEdge? addEdge(bool isA, Coordinate? dirPt, int dim, bool isForward) {
    if (dirPt == null) return null;

    if (nodePt.equals2D(dirPt)) {
      return null;
    }

    int insertIndex = -1;
    for (int i = 0; i < _edges.size; i++) {
      RelateEdge e = _edges.get(i);
      int comp = e.compareToEdge(dirPt);
      if (comp == 0) {
        e.merge(isA, dirPt, dim, isForward);
        return e;
      }
      if (comp == 1) {
        insertIndex = i;
        break;
      }
    }
    RelateEdge e = RelateEdge.create(this, dirPt, isA, dim, isForward);
    if (insertIndex < 0) {
      _edges.add(e);
    } else {
      _edges.insert(insertIndex, e);
    }
    return e;
  }

  void finish(bool isAreaInteriorA, bool isAreaInteriorB) {
    finishNode(RelateGeometry.GEOM_A, isAreaInteriorA);
    finishNode(RelateGeometry.GEOM_B, isAreaInteriorB);
  }

  void finishNode(bool isA, bool isAreaInterior) {
    if (isAreaInterior) {
      RelateEdge.setAreaInterior2(_edges, isA);
    } else {
      int startIndex = RelateEdge.findKnownEdgeIndex(_edges, isA);
      propagateSideLocations(isA, startIndex);
    }
  }

  void propagateSideLocations(bool isA, int startIndex) {
    int currLoc = _edges.get(startIndex).location(isA, Position.left);
    int index = nextIndex(_edges, startIndex);
    while (index != startIndex) {
      RelateEdge e = _edges.get(index);
      e.setUnknownLocations(isA, currLoc);
      currLoc = e.location(isA, Position.left);
      index = nextIndex(_edges, index);
    }
  }

  static int prevIndex(List<RelateEdge> list, int index) {
    if (index > 0) return index - 1;

    return list.size - 1;
  }

  static int nextIndex(List<RelateEdge> list, int i) {
    if (i >= (list.size - 1)) {
      return 0;
    }
    return i + 1;
  }

  bool hasExteriorEdge(bool isA) {
    for (RelateEdge e in _edges) {
      if ((Location.exterior == e.location(isA, Position.left)) ||
          (Location.exterior == e.location(isA, Position.right))) {
        return true;
      }
    }
    return false;
  }
}
