import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/triangulate/quadedge/quad_edge.dart';
import 'package:dts/src/jts/triangulate/quadedge/quad_edge_subdivision.dart';
import 'package:dts/src/jts/triangulate/quadedge/vertex.dart';

class IncrementalDelaunayTriangulator {
  QuadEdgeSubdivision subdiv;

  bool _isUsingTolerance = false;

  bool _isForceConvex = true;

  IncrementalDelaunayTriangulator(this.subdiv) {
    _isUsingTolerance = subdiv.getTolerance() > 0.0;
  }

  void forceConvex(bool isForceConvex) {
    _isForceConvex = isForceConvex;
  }

  void insertSites(List<Vertex> vertices) {
    for (var i = vertices.iterator; i.moveNext();) {
      Vertex v = i.current;
      insertSite(v);
    }
  }

  QuadEdge insertSite(Vertex v) {
    QuadEdge e = subdiv.locate(v)!;
    if (subdiv.isVertexOfEdge(e, v)) {
      return e;
    } else if (subdiv.isOnEdge(e, v.getCoordinate())) {
      e = e.oPrev();
      subdiv.delete(e.oNext());
    }
    QuadEdge base = subdiv.makeEdge(e.orig(), v);
    QuadEdge.splice(base, e);
    QuadEdge startEdge = base;
    do {
      base = subdiv.connect(e, base.sym());
      e = base.oPrev();
    } while (e.lNext() != startEdge);
    do {
      QuadEdge t = e.oPrev();
      bool doFlip = t.dest().rightOf(e) && v.isInCircle(e.orig(), t.dest(), e.dest());
      if (_isForceConvex) {
        if (isConcaveBoundary(e)) {
          doFlip = true;
        } else if (isBetweenFrameAndInserted(e, v)) {
          doFlip = false;
        }
      }
      if (doFlip) {
        QuadEdge.swap(e);
        e = e.oPrev();
        continue;
      }
      if (e.oNext() == startEdge) {
        return base;
      }
      e = e.oNext().lPrev()!;
    } while (true);
  }

  bool isConcaveBoundary(QuadEdge e) {
    if (subdiv.isFrameVertex(e.dest())) {
      return isConcaveAtOrigin(e);
    }
    if (subdiv.isFrameVertex(e.orig())) {
      return isConcaveAtOrigin(e.sym());
    }
    return false;
  }

  static bool isConcaveAtOrigin(QuadEdge e) {
    Coordinate p = e.orig().getCoordinate();
    Coordinate pp = e.oPrev().dest().getCoordinate();
    Coordinate pn = e.oNext().dest().getCoordinate();
    bool isConcave = Orientation.counterClockwise == Orientation.index(pp, pn, p);
    return isConcave;
  }

  bool isBetweenFrameAndInserted(QuadEdge e, Vertex vInsert) {
    Vertex v1 = e.oNext().dest();
    Vertex v2 = e.oPrev().dest();
    return ((v1 == vInsert) && subdiv.isFrameVertex(v2)) || ((v2 == vInsert) && subdiv.isFrameVertex(v1));
  }
}
