 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/point_location.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'quad_edge.dart';
import 'quad_edge_subdivision.dart';
import 'triangle_visitor.dart';
import 'vertex.dart';

class QuadEdgeTriangle {
  static List createOn(QuadEdgeSubdivision subdiv) {
    final visitor = QuadEdgeTriangleBuilderVisitor();
    subdiv.visitTriangles(visitor, false);
    return visitor.getTriangles();
  }

  static bool contains2(Array<Vertex> tri, Coordinate pt) {
    Array<Coordinate> ring =
        [tri[0].getCoordinate(), tri[1].getCoordinate(), tri[2].getCoordinate(), tri[0].getCoordinate()].toArray();
    return PointLocation.isInRing(pt, ring);
  }

  static bool contains3(Array<QuadEdge> tri, Coordinate pt) {
    Array<Coordinate> ring =
        [
          tri[0].orig().getCoordinate(),
          tri[1].orig().getCoordinate(),
          tri[2].orig().getCoordinate(),
          tri[0].orig().getCoordinate(),
        ].toArray();
    return PointLocation.isInRing(pt, ring);
  }

  static Geometry toPolygon2(Array<Vertex> v) {
    Array<Coordinate> ringPts =
        [v[0].getCoordinate(), v[1].getCoordinate(), v[2].getCoordinate(), v[0].getCoordinate()].toArray();
    GeometryFactory fact = GeometryFactory.empty();
    LinearRing ring = fact.createLinearRing2(ringPts);
    return fact.createPolygon(ring);
  }

  static Geometry toPolygon(Array<QuadEdge> e) {
    Array<Coordinate> ringPts =
        [
          e[0].orig().getCoordinate(),
          e[1].orig().getCoordinate(),
          e[2].orig().getCoordinate(),
          e[0].orig().getCoordinate(),
        ].toArray();
    GeometryFactory fact = GeometryFactory.empty();
    LinearRing ring = fact.createLinearRing2(ringPts);
    Polygon tri = fact.createPolygon(ring);
    return tri;
  }

  static int nextIndex(int index) {
    return index = (index + 1) % 3;
  }

  Array<QuadEdge>? _edge;

  Object? data;

  QuadEdgeTriangle(Array<QuadEdge> edge) {
    _edge = edge.copy();

    for (int i = 0; i < 3; i++) {
      edge[i].data = this;
    }
  }

  void kill() {
    _edge = null;
  }

  bool isLive() {
    return _edge != null;
  }

  Array<QuadEdge>? getEdges() {
    return _edge;
  }

  QuadEdge getEdge(int i) {
    return _edge![i];
  }

  Vertex? getVertex(int i) {
    return _edge![i].orig();
  }

  Array<Vertex> getVertices() {
    Array<Vertex> vert = Array(3);
    for (int i = 0; i < 3; i++) {
      vert[i] = getVertex(i)!;
    }
    return vert;
  }

  Coordinate getCoordinate(int i) {
    return _edge![i].orig().getCoordinate();
  }

  int getEdgeIndex(QuadEdge e) {
    for (int i = 0; i < 3; i++) {
      if (_edge![i] == e) return i;
    }
    return -1;
  }

  int getEdgeIndex2(Vertex v) {
    for (int i = 0; i < 3; i++) {
      if (_edge![i].orig() == v) return i;
    }
    return -1;
  }

  void getEdgeSegment(int i, LineSegment seg) {
    seg.p0 = _edge![i].orig().getCoordinate();
    int nexti = (i + 1) % 3;
    seg.p1 = _edge![nexti].orig().getCoordinate();
  }

  Array<Coordinate> getCoordinates() {
    Array<Coordinate> pts = Array(4);
    for (int i = 0; i < 3; i++) {
      pts[i] = _edge![i].orig().getCoordinate();
    }
    pts[3] = Coordinate.of(pts[0]);
    return pts;
  }

  bool contains(Coordinate pt) {
    Array<Coordinate> ring = getCoordinates();
    return PointLocation.isInRing(pt, ring);
  }

  Polygon getGeometry(GeometryFactory fact) {
    LinearRing ring = fact.createLinearRing2(getCoordinates());
    Polygon tri = fact.createPolygon(ring);
    return tri;
  }

  bool isBorder() {
    for (int i = 0; i < 3; i++) {
      if (getAdjacentTriangleAcrossEdge(i) == null) return true;
    }
    return false;
  }

  bool isBorder2(int i) {
    return getAdjacentTriangleAcrossEdge(i) == null;
  }

  QuadEdgeTriangle? getAdjacentTriangleAcrossEdge(int edgeIndex) {
    return getEdge(edgeIndex).sym().data as QuadEdgeTriangle?;
  }

  int getAdjacentTriangleEdgeIndex(int i) {
    return getAdjacentTriangleAcrossEdge(i)!.getEdgeIndex(getEdge(i).sym());
  }

  List<QuadEdgeTriangle> getTrianglesAdjacentToVertex(int vertexIndex) {
    List<QuadEdgeTriangle> adjTris = [];
    QuadEdge start = getEdge(vertexIndex);
    QuadEdge? qe = start;
    do {
      final adjTri = qe!.data as QuadEdgeTriangle?;
      if (adjTri != null) {
        adjTris.add(adjTri);
      }
      qe = qe.oNext();
    } while (qe != start);
    return adjTris;
  }

  Array<QuadEdgeTriangle> getNeighbours() {
    Array<QuadEdgeTriangle> neigh = Array(3);
    for (int i = 0; i < 3; i++) {
      neigh[i] = getEdge(i).sym().data as QuadEdgeTriangle;
    }
    return neigh;
  }
}

class QuadEdgeTriangleBuilderVisitor implements TriangleVisitor {
  final List _triangles = [];

  @override
  void visit(Array<QuadEdge> edges) {
    _triangles.add(QuadEdgeTriangle(edges));
  }

  List getTriangles() {
    return _triangles;
  }
}
