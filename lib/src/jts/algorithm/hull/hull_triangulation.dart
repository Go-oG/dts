import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/triangle.dart';
import 'package:dts/src/jts/operation/overlayng/coverage_union.dart';
import 'package:dts/src/jts/triangulate/delaunay_triangulation_builder.dart';
import 'package:dts/src/jts/triangulate/quadedge/quad_edge.dart';
import 'package:dts/src/jts/triangulate/quadedge/quad_edge_subdivision.dart';
import 'package:dts/src/jts/triangulate/quadedge/triangle_visitor.dart';
import 'package:dts/src/jts/triangulate/tri/tri.dart';
import 'package:dts/src/jts/triangulate/tri/triangulation_builder.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'hull_tri.dart';

class HullTriangulation {
  static List<HullTri> createDelaunayTriangulation(Geometry geom) {
    final dt = DelaunayTriangulationBuilder();
    dt.setSites2(geom);
    QuadEdgeSubdivision subdiv = dt.getSubdivision();
    return _toTris(subdiv);
  }

  static List<HullTri> _toTris(QuadEdgeSubdivision subdiv) {
    _HullTriVisitor visitor = _HullTriVisitor();
    subdiv.visitTriangles(visitor, false);
    List<HullTri> triList = visitor.getTriangles();
    TriangulationBuilder.build(triList);
    return triList;
  }

  static Geometry union<T extends Tri>(List<T> triList, GeomFactory geomFactory) {
    List<Polygon> polys = [];
    for (Tri tri in triList) {
      Polygon poly = tri.toPolygon(geomFactory);
      polys.add(poly);
    }
    return CoverageUnionNG.union(geomFactory.buildGeometry(polys));
  }

  static Geometry traceBoundaryPolygon(List<HullTri> triList, GeomFactory geomFactory) {
    if (triList.size == 1) {
      Tri tri = triList.get(0);
      return tri.toPolygon(geomFactory);
    }
    Array<Coordinate> pts = _traceBoundary(triList);
    return geomFactory.createPolygon3(pts);
  }

  static Array<Coordinate> _traceBoundary(List<HullTri> triList) {
    HullTri triStart = _findBorderTri(triList)!;
    CoordinateList coordList = CoordinateList();
    HullTri tri = triStart;
    do {
      int boundaryIndex = tri.boundaryIndexCCW();
      coordList.add3(tri.getCoordinate(boundaryIndex).copy(), false);
      int nextIndex = Tri.next(boundaryIndex);
      if (tri.isBoundary(nextIndex)) {
        coordList.add3(tri.getCoordinate(nextIndex).copy(), false);
        boundaryIndex = nextIndex;
      }
      tri = nextBorderTri(tri);
    } while (tri != triStart);
    coordList.closeRing();
    return coordList.toCoordinateArray();
  }

  static HullTri? _findBorderTri(List<HullTri> triList) {
    for (HullTri tri in triList) {
      if (tri.isBorder()) {
        return tri;
      }
    }
    Assert.shouldNeverReachHere2("No border triangles found");
    return null;
  }

  static HullTri nextBorderTri(HullTri triStart) {
    HullTri tri = triStart;
    int index = Tri.next(tri.boundaryIndexCW());
    do {
      HullTri adjTri = (tri.getAdjacent(index) as HullTri);
      if (adjTri == tri) {
        throw ("No outgoing border edge found");
      }

      index = Tri.next(adjTri.getIndex2(tri));
      tri = adjTri;
    } while (!tri.isBoundary(index));
    return tri;
  }
}

class _HullTriVisitor implements TriangleVisitor {
  List<HullTri> triList = [];

  @override
  void visit(Array<QuadEdge> triEdges) {
    Coordinate p0 = triEdges[0].orig().getCoordinate();
    Coordinate p1 = triEdges[1].orig().getCoordinate();
    Coordinate p2 = triEdges[2].orig().getCoordinate();
    HullTri tri;
    if (Triangle.isCCW2(p0, p1, p2)) {
      tri = HullTri(p0, p2, p1);
    } else {
      tri = HullTri(p0, p1, p2);
    }
    triList.add(tri);
  }

  List<HullTri> getTriangles() {
    return triList;
  }
}
