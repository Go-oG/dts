 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/triangle.dart';
import 'package:dts/src/jts/util/assert.dart';

class Tri {
  static final String _INVALID_TRI_INDEX = "Invalid Tri index";

  static Geometry toGeometry(List<Tri> tris, GeometryFactory geomFact) {
    Array<Geometry> geoms = Array(tris.size);
    int i = 0;
    for (Tri tri in tris) {
      geoms[i++] = tri.toPolygon(geomFact);
    }
    return geomFact.createGeometryCollection2(geoms);
  }

  static double area<T extends Tri>(List<T> triList) {
    double area = 0;
    for (var tri in triList) {
      area += tri.getArea();
    }
    return area;
  }

  static void validate2(List<Tri> triList) {
    for (Tri tri in triList) {
      tri.validate();
    }
  }

  static Tri create2(Coordinate p0, Coordinate p1, Coordinate p2) {
    return Tri(p0, p1, p2);
  }

  static Tri create(Array<Coordinate> pts) {
    return Tri(pts[0], pts[1], pts[2]);
  }

  Coordinate p0;

  Coordinate p1;

  Coordinate p2;

  Tri? tri0;

  Tri? tri1;

  Tri? tri2;

  Tri(this.p0, this.p1, this.p2);

  void setAdjacent(Tri? tri0, Tri? tri1, Tri? tri2) {
    this.tri0 = tri0;
    this.tri1 = tri1;
    this.tri2 = tri2;
  }

  void setAdjacent2(Coordinate pt, Tri tri) {
    int index = getIndex(pt);
    setTri(index, tri);
  }

  void setTri(int edgeIndex, Tri? tri) {
    switch (edgeIndex) {
      case 0:
        tri0 = tri;
        return;
      case 1:
        tri1 = tri;
        return;
      case 2:
        tri2 = tri;
        return;
    }
    throw IllegalArgumentException(_INVALID_TRI_INDEX);
  }

  void setCoordinates(Coordinate p0, Coordinate p1, Coordinate p2) {
    this.p0 = p0;
    this.p1 = p1;
    this.p2 = p2;
  }

  Tri split(Coordinate p) {
    Tri tt0 = Tri(p, p0, p1);
    Tri tt1 = Tri(p, p1, p2);
    Tri tt2 = Tri(p, p2, p0);
    tt0.setAdjacent(tt2, tri0, tt1);
    tt1.setAdjacent(tt0, tri1, tt2);
    tt2.setAdjacent(tt1, tri2, tt0);
    return tt0;
  }

  void flip(int index) {
    Tri tri = getAdjacent(index)!;
    int index1 = tri.getIndex2(this);
    Coordinate adj0 = getCoordinate(index);
    Coordinate adj1 = getCoordinate(next(index));
    Coordinate opp0 = getCoordinate(oppVertex(index));
    Coordinate opp1 = tri.getCoordinate(oppVertex(index1));
    flip2(tri, index, index1, adj0, adj1, opp0, opp1);
  }

  void flip2(Tri tri, int index0, int index1, Coordinate adj0, Coordinate adj1, Coordinate opp0, Coordinate opp1) {
    setCoordinates(opp1, opp0, adj0);
    tri.setCoordinates(opp0, opp1, adj1);
    Array<Tri?> adjacent = getAdjacentTris(tri, index0, index1);
    setAdjacent(tri, adjacent[0], adjacent[2]);
    if (adjacent[2] != null) {
      adjacent[2]!.replace(tri, this);
    }
    tri.setAdjacent(this, adjacent[3], adjacent[1]);
    if (adjacent[1] != null) {
      adjacent[1]!.replace(this, tri);
    }
  }

  void replace(Tri triOld, Tri triNew) {
    if ((tri0 != null) && (tri0 == triOld)) {
      tri0 = triNew;
    } else if ((tri1 != null) && (tri1 == triOld)) {
      tri1 = triNew;
    } else if ((tri2 != null) && (tri2 == triOld)) {
      tri2 = triNew;
    }
  }

  int degree<T extends Tri>(int index, List<T> triList) {
    Coordinate v = getCoordinate(index);
    int degree = 0;
    for (var tri in triList) {
      for (int i = 0; i < 3; i++) {
        if (v.equals2D(tri.getCoordinate(i))) degree++;
      }
    }
    return degree;
  }

  void remove(List<Tri> triList) {
    remove2();
    triList.remove(this);
  }

  void remove2() {
    remove3(0);
    remove3(1);
    remove3(2);
  }

  void remove3(int index) {
    Tri? adj = getAdjacent(index);
    if (adj == null) return;

    adj.setTri(adj.getIndex2(this), null);
    setTri(index, null);
  }

  Array<Tri?> getAdjacentTris(Tri triAdj, int index, int indexAdj) {
    Array<Tri?> adj = Array(4);
    adj[0] = getAdjacent(prev(index));
    adj[1] = getAdjacent(next(index));
    adj[2] = triAdj.getAdjacent(next(indexAdj));
    adj[3] = triAdj.getAdjacent(prev(indexAdj));
    return adj;
  }

  void validate() {
    if (Orientation.clockwise != Orientation.index(p0, p1, p2)) {
      throw IllegalArgumentException("Tri is not oriented correctly");
    }
    validateAdjacent(0);
    validateAdjacent(1);
    validateAdjacent(2);
  }

  void validateAdjacent(int index) {
    Tri? tri = getAdjacent(index);
    if (tri == null) return;

    ///TODO 改动
    // assert this.isAdjacent(tri);
    // assert tri.isAdjacent(this);

    Coordinate e0 = getCoordinate(index);
    Coordinate e1 = getCoordinate(next(index));
    int indexNeighbor = tri.getIndex2(this);
    Coordinate n0 = tri.getCoordinate(indexNeighbor);
    Coordinate n1 = tri.getCoordinate(next(indexNeighbor));
    Assert.isTrue2(e0.equals2D(n1), "Edge coord not equal");
    Assert.isTrue2(e1.equals2D(n0), "Edge coord not equal");
    RobustLineIntersector li = RobustLineIntersector();
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        Coordinate p00 = getCoordinate(i);
        Coordinate p01 = getCoordinate(next(i));
        Coordinate p10 = tri.getCoordinate(j);
        Coordinate p11 = tri.getCoordinate(next(j));
        li.computeIntersection2(p00, p01, p10, p11);

        ///TODO 改动
        // assert !li.isProper();
      }
    }
  }

  Coordinate getCoordinate(int index) {
    switch (index) {
      case 0:
        return p0;
      case 1:
        return p1;
      case 2:
        return p2;
    }
    throw IllegalArgumentException(_INVALID_TRI_INDEX);
  }

  int getIndex(Coordinate p) {
    if (p0.equals2D(p)) return 0;

    if (p1.equals2D(p)) return 1;

    if (p2.equals2D(p)) return 2;

    return -1;
  }

  int getIndex2(Tri tri) {
    if (tri0 == tri) return 0;

    if (tri1 == tri) return 1;

    if (tri2 == tri) return 2;

    return -1;
  }

  Tri? getAdjacent(int index) {
    switch (index) {
      case 0:
        return tri0;
      case 1:
        return tri1;
      case 2:
        return tri2;
    }
    throw "IllegalArgumentException $_INVALID_TRI_INDEX";
  }

  bool hasAdjacent() {
    return (hasAdjacent2(0) || hasAdjacent2(1)) || hasAdjacent2(2);
  }

  bool hasAdjacent2(int index) {
    return null != getAdjacent(index);
  }

  bool isAdjacent(Tri tri) {
    return getIndex2(tri) >= 0;
  }

  int numAdjacent() {
    int num = 0;
    if (tri0 != null) num++;

    if (tri1 != null) num++;

    if (tri2 != null) num++;

    return num;
  }

  bool isInteriorVertex(int index) {
    Tri curr = this;
    int currIndex = index;
    do {
      Tri? adj = curr.getAdjacent(currIndex);
      if (adj == null) return false;

      int adjIndex = adj.getIndex2(curr);
      if (adjIndex < 0) {
        throw ("Inconsistent adjacency - invalid triangulation");
      }
      curr = adj;
      currIndex = Tri.next(adjIndex);
    } while (curr != this);
    return true;
  }

  bool isBorder() {
    return (isBoundary(0) || isBoundary(1)) || isBoundary(2);
  }

  bool isBoundary(int index) {
    return !hasAdjacent2(index);
  }

  static int next(int index) {
    switch (index) {
      case 0:
        return 1;
      case 1:
        return 2;
      case 2:
        return 0;
    }
    return -1;
  }

  static int prev(int index) {
    switch (index) {
      case 0:
        return 2;
      case 1:
        return 0;
      case 2:
        return 1;
    }
    return -1;
  }

  static int oppVertex(int edgeIndex) {
    return prev(edgeIndex);
  }

  static int oppEdge(int vertexIndex) {
    return next(vertexIndex);
  }

  Coordinate midpoint(int edgeIndex) {
    Coordinate p0 = getCoordinate(edgeIndex);
    Coordinate p1 = getCoordinate(next(edgeIndex));
    double midX = (p0.getX() + p1.getX()) / 2;
    double midY = (p0.getY() + p1.getY()) / 2;
    return Coordinate(midX, midY);
  }

  double getArea() {
    return Triangle.area2(p0, p1, p2);
  }

  double getLength() {
    return Triangle.length2(p0, p1, p2);
  }

  double getLength2(int edgeIndex) {
    return getCoordinate(edgeIndex).distance(getCoordinate(next(edgeIndex)));
  }

  Polygon toPolygon(GeometryFactory geomFact) {
    return geomFact.createPolygon(
      geomFact.createLinearRing2([p0.copy(), p1.copy(), p2.copy(), p0.copy()].toArray()),
      null,
    );
  }
}
