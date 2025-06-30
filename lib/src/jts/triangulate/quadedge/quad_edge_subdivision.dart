import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/triangle.dart';

import 'last_found_quad_edge_locator.dart';
import 'locate_failure_exception.dart';
import 'quad_edge.dart';
import 'quad_edge_locator.dart';
import 'triangle_visitor.dart';
import 'vertex.dart';

class QuadEdgeSubdivision {
  static void getTriangleEdges2(QuadEdge startQE, Array<QuadEdge> triEdge) {
    triEdge[0] = startQE;
    triEdge[1] = triEdge[0].lNext();
    triEdge[2] = triEdge[1].lNext();
    if (triEdge[2].lNext() != triEdge[0]) throw ("Edges do not form a triangle");
  }

  static const double _kEdgeCoincidenceTolFactor = 1000;
  static const double _kFrameSizeFactor = 10.0;

  final List<QuadEdge> _quadEdges = [];

  late QuadEdge _startingEdge;

  double tolerance;

  double _edgeCoincidenceTolerance = 0;

  final Array<Vertex> _frameVertex = Array(3);

  late Envelope _frameEnv;

  late QuadEdgeLocator _locator;

  QuadEdgeSubdivision(Envelope env, this.tolerance) {
    _edgeCoincidenceTolerance = tolerance / _kEdgeCoincidenceTolFactor;
    createFrame(env);
    _startingEdge = initSubdiv();
    _locator = LastFoundQuadEdgeLocator(this);
  }

  void createFrame(Envelope env) {
    double deltaX = env.width;
    double deltaY = env.height;
    double frameSize = Math.max(deltaX, deltaY) * _kFrameSizeFactor;
    _frameVertex[0] = Vertex((env.maxX + env.minX) / 2.0, env.maxY + frameSize);
    _frameVertex[1] = Vertex(env.minX - frameSize, env.minY - frameSize);
    _frameVertex[2] = Vertex(env.maxX + frameSize, env.minY - frameSize);
    _frameEnv =
        Envelope.fromCoordinate(_frameVertex[0].getCoordinate(), _frameVertex[1].getCoordinate());
    _frameEnv.expandToIncludeCoordinate(_frameVertex[2].getCoordinate());
  }

  QuadEdge initSubdiv() {
    QuadEdge ea = makeEdge(_frameVertex[0], _frameVertex[1]);
    QuadEdge eb = makeEdge(_frameVertex[1], _frameVertex[2]);
    QuadEdge.splice(ea.sym(), eb);
    QuadEdge ec = makeEdge(_frameVertex[2], _frameVertex[0]);
    QuadEdge.splice(eb.sym(), ec);
    QuadEdge.splice(ec.sym(), ea);
    return ea;
  }

  double getTolerance() {
    return tolerance;
  }

  Envelope getEnvelope() {
    return Envelope.from(_frameEnv);
  }

  List<QuadEdge> getEdges() {
    return _quadEdges;
  }

  void setLocator(QuadEdgeLocator locator) {
    _locator = locator;
  }

  QuadEdge makeEdge(Vertex o, Vertex d) {
    QuadEdge q = QuadEdge.makeEdge(o, d);
    _quadEdges.add(q);
    return q;
  }

  QuadEdge connect(QuadEdge a, QuadEdge b) {
    QuadEdge q = QuadEdge.connect(a, b);
    _quadEdges.add(q);
    return q;
  }

  void delete(QuadEdge e) {
    QuadEdge.splice(e, e.oPrev());
    QuadEdge.splice(e.sym(), e.sym().oPrev());
    QuadEdge eSym = e.sym();
    QuadEdge eRot = e.rot();
    QuadEdge eRotSym = e.rot().sym();
    _quadEdges.remove(e);
    _quadEdges.remove(eSym);
    _quadEdges.remove(eRot);
    _quadEdges.remove(eRotSym);
    e.delete();
    eSym.delete();
    eRot.delete();
    eRotSym.delete();
  }

  QuadEdge locateFromEdge(Vertex v, QuadEdge startEdge) {
    int iter = 0;
    int maxIter = _quadEdges.size;
    QuadEdge e = startEdge;
    while (true) {
      iter++;
      if (iter > maxIter) {
        throw LocateFailureException("", e.toLineSegment());
      }
      if (v.equals(e.orig()) || v.equals(e.dest())) {
        break;
      } else if (v.rightOf(e)) {
        e = e.sym();
      } else if (!v.rightOf(e.oNext())) {
        e = e.oNext();
      } else if (!v.rightOf(e.dPrev()!)) {
        e = e.dPrev()!;
      } else {
        break;
      }
    }
    return e;
  }

  QuadEdge? locate(Vertex v) {
    return _locator.locate(v);
  }

  QuadEdge? locate2(Coordinate p) {
    return _locator.locate(Vertex.of(p));
  }

  QuadEdge? locate3(Coordinate p0, Coordinate p1) {
    QuadEdge? e = _locator.locate(Vertex.of(p0));
    if (e == null) {
      return null;
    }

    QuadEdge base = e;
    if (e.dest().getCoordinate().equals2D(p0)) {
      base = e.sym();
    }

    QuadEdge locEdge = base;
    do {
      if (locEdge.dest().getCoordinate().equals2D(p1)) {
        return locEdge;
      }

      locEdge = locEdge.oNext();
    } while (locEdge != base);
    return null;
  }

  QuadEdge insertSite(Vertex v) {
    QuadEdge e = locate(v)!;
    if (v.equals2(e.orig(), tolerance) || v.equals2(e.dest(), tolerance)) {
      return e;
    }
    QuadEdge base = makeEdge(e.orig(), v);
    QuadEdge.splice(base, e);
    QuadEdge startEdge = base;
    do {
      base = connect(e, base.sym());
      e = base.oPrev();
    } while (e.lNext() != startEdge);
    return startEdge;
  }

  bool isFrameEdge(QuadEdge e) {
    if (isFrameVertex(e.orig()) || isFrameVertex(e.dest())) return true;

    return false;
  }

  bool isFrameBorderEdge(QuadEdge e) {
    Array<QuadEdge> leftTri = Array(3);
    getTriangleEdges2(e, leftTri);
    Array<QuadEdge> rightTri = Array(3);
    getTriangleEdges2(e.sym(), rightTri);
    Vertex vLeftTriOther = e.lNext().dest();
    if (isFrameVertex(vLeftTriOther)) {
      return true;
    }

    Vertex vRightTriOther = e.sym().lNext().dest();
    if (isFrameVertex(vRightTriOther)) {
      return true;
    }

    return false;
  }

  bool isFrameVertex(Vertex v) {
    if (v.equals(_frameVertex[0])) return true;

    if (v.equals(_frameVertex[1])) return true;

    if (v.equals(_frameVertex[2])) return true;

    return false;
  }

  LineSegment seg = LineSegment.empty();

  bool isOnEdge(QuadEdge e, Coordinate p) {
    seg.setCoordinates2(e.orig().getCoordinate(), e.dest().getCoordinate());
    double dist = seg.distance(p);
    return dist < _edgeCoincidenceTolerance;
  }

  bool isVertexOfEdge(QuadEdge e, Vertex v) {
    if (v.equals2(e.orig(), tolerance) || v.equals2(e.dest(), tolerance)) {
      return true;
    }
    return false;
  }

  Set getVertices(bool includeFrame) {
    Set<Vertex> vertices = <Vertex>{};

    for (var i = _quadEdges.iterator; i.moveNext();) {
      QuadEdge qe = i.current;
      Vertex v = qe.orig();
      if (includeFrame || (!isFrameVertex(v))) vertices.add(v);

      Vertex vd = qe.dest();
      if (includeFrame || (!isFrameVertex(vd))) vertices.add(vd);
    }
    return vertices;
  }

  List<QuadEdge> getVertexUniqueEdges(bool includeFrame) {
    List<QuadEdge> edges = [];
    Set<Vertex> visitedVertices = <Vertex>{};
    for (Iterator i = _quadEdges.iterator; i.moveNext();) {
      QuadEdge qe = i.current;
      Vertex v = qe.orig();
      if (!visitedVertices.contains(v)) {
        visitedVertices.add(v);
        if (includeFrame || (!isFrameVertex(v))) {
          edges.add(qe);
        }
      }
      QuadEdge qd = qe.sym();
      Vertex vd = qd.orig();
      if (!visitedVertices.contains(vd)) {
        visitedVertices.add(vd);
        if (includeFrame || (!isFrameVertex(vd))) {
          edges.add(qd);
        }
      }
    }
    return edges;
  }

  List<QuadEdge> getPrimaryEdges(bool includeFrame) {
    List<QuadEdge> edges = [];
    Stack edgeStack = Stack();
    edgeStack.push(_startingEdge);
    Set<QuadEdge> visitedEdges = <QuadEdge>{};
    while (edgeStack.isNotEmpty) {
      QuadEdge edge = edgeStack.pop();
      if (!visitedEdges.contains(edge)) {
        QuadEdge priQE = edge.getPrimary()!;
        if (includeFrame || (!isFrameEdge(priQE))) {
          edges.add(priQE);
        }
        edgeStack.push(edge.oNext());
        edgeStack.push(edge.sym().oNext());
        visitedEdges.add(edge);
        visitedEdges.add(edge.sym());
      }
    }
    return edges;
  }

  List<QuadEdge> getFrameEdges() {
    List<QuadEdge> edges = getPrimaryEdges(true);
    List<QuadEdge> frameEdges = [];
    for (QuadEdge e in edges) {
      if (isFrameEdge(e)) {
        QuadEdge fe = (isFrameVertex(e.orig())) ? e : e.sym();
        frameEdges.add(fe);
      }
    }
    return frameEdges;
  }

  void visitTriangles(TriangleVisitor triVisitor, bool includeFrame) {
    Stack<QuadEdge> edgeStack = Stack();
    edgeStack.push(_startingEdge);
    final visitedEdges = <QuadEdge>{};
    while (edgeStack.isNotEmpty) {
      QuadEdge edge = edgeStack.pop();
      if (!visitedEdges.contains(edge)) {
        Array<QuadEdge>? triEdges =
            fetchTriangleToVisit(edge, edgeStack, includeFrame, visitedEdges);
        if (triEdges != null) {
          triVisitor.visit(triEdges);
        }
      }
    }
  }

  final Array<QuadEdge> _triEdges = Array(3);

  Array<QuadEdge>? fetchTriangleToVisit(
      QuadEdge edge, Stack edgeStack, bool includeFrame, Set visitedEdges) {
    QuadEdge curr = edge;
    int edgeCount = 0;
    bool isFrame = false;
    do {
      _triEdges[edgeCount] = curr;
      if (isFrameEdge(curr)) isFrame = true;

      QuadEdge sym = curr.sym();
      if (!visitedEdges.contains(sym)) edgeStack.push(sym);

      visitedEdges.add(curr);
      edgeCount++;
      curr = curr.lNext();
    } while (curr != edge);
    if (isFrame && (!includeFrame)) return null;

    return _triEdges;
  }

  List getTriangleEdges(bool includeFrame) {
    TriangleEdgesListVisitor visitor = TriangleEdgesListVisitor();
    visitTriangles(visitor, includeFrame);
    return visitor.getTriangleEdges();
  }

  List<Array<Vertex>> getTriangleVertices(bool includeFrame) {
    TriangleVertexListVisitor visitor = TriangleVertexListVisitor();
    visitTriangles(visitor, includeFrame);
    return visitor.getTriangleVertices();
  }

  List<Array<Coordinate>> getTriangleCoordinates(bool includeFrame) {
    TriangleCoordinatesVisitor visitor = TriangleCoordinatesVisitor();
    visitTriangles(visitor, includeFrame);
    return visitor.getTriangles();
  }

  Geometry getEdges2(GeomFactory geomFact) {
    final quadEdges = getPrimaryEdges(false);
    Array<LineString> edges = Array(quadEdges.size);
    int i = 0;
    for (Iterator it = quadEdges.iterator; it.moveNext();) {
      QuadEdge qe = it.current;
      edges[i++] = geomFact
          .createLineString2([qe.orig().getCoordinate(), qe.dest().getCoordinate()].toArray());
    }
    return geomFact.createMultiLineString(edges);
  }

  Geometry getTriangles2(GeomFactory geomFact) {
    final triPtsList = getTriangleCoordinates(false);
    Array<Polygon> tris = Array(triPtsList.size);
    int i = 0;
    for (var it = triPtsList.iterator; it.moveNext();) {
      Array<Coordinate> triPt = it.current;
      tris[i++] = geomFact.createPolygon(geomFact.createLinearRings(triPt));
    }
    return geomFact.createGeomCollection(tris);
  }

  Geometry getTriangles(bool includeFrame, GeomFactory geomFact) {
    final triPtsList = getTriangleCoordinates(includeFrame);
    Array<Polygon> tris = Array(triPtsList.size);
    int i = 0;
    for (var it = triPtsList.iterator; it.moveNext();) {
      Array<Coordinate> triPt = it.current;
      tris[i++] = geomFact.createPolygon(geomFact.createLinearRings(triPt));
    }
    return geomFact.createGeomCollection(tris);
  }

  Geometry getVoronoiDiagram(GeomFactory geomFact) {
    final vorCells = getVoronoiCellPolygons(geomFact);
    return geomFact.createGeomCollection(GeomFactory.toGeometryArray(vorCells)!);
  }

  List<Polygon> getVoronoiCellPolygons(GeomFactory geomFact) {
    visitTriangles(TriangleCircumcentreVisitor(), true);
    List<Polygon> cells = [];
    List edges = getVertexUniqueEdges(false);
    for (Iterator i = edges.iterator; i.moveNext();) {
      QuadEdge qe = i.current;
      cells.add(getVoronoiCellPolygon(qe, geomFact));
    }
    return cells;
  }

  Polygon getVoronoiCellPolygon(QuadEdge qe, GeomFactory geomFact) {
    List<Coordinate> cellPts = [];
    QuadEdge startQE = qe;
    do {
      Coordinate cc = qe.rot().orig().getCoordinate();
      cellPts.add(cc);
      qe = qe.oPrev();
    } while (qe != startQE);
    CoordinateList coordList = CoordinateList();
    coordList.addAll(cellPts, false);
    coordList.closeRing();
    if (coordList.size < 4) {
      coordList.add3(coordList.last, true);
    }
    Array<Coordinate> pts = coordList.toCoordinateArray();
    Polygon cellPoly = geomFact.createPolygon(geomFact.createLinearRings(pts));
    Vertex v = startQE.orig();
    cellPoly.userData = v.getCoordinate();
    return cellPoly;
  }

  bool isDelaunay() {
    List<QuadEdge> edges = getPrimaryEdges(true);
    for (QuadEdge e in edges) {
      Vertex a0 = e.oPrev().dest();
      Vertex a1 = e.oNext().dest();
      bool isDelaunay = !a1.isInCircle(e.orig(), a0, e.dest());
      if (!isDelaunay) {
        return false;
      }
    }
    return true;
  }
}

class TriangleCoordinatesVisitor implements TriangleVisitor {
  CoordinateList coordList = CoordinateList();

  final List<Array<Coordinate>> _triCoords = [];

  @override
  void visit(Array<QuadEdge> triEdges) {
    coordList.clear();
    for (int i = 0; i < 3; i++) {
      Vertex v = triEdges[i].orig();
      coordList.add(v.getCoordinate());
    }
    if (coordList.size > 0) {
      coordList.closeRing();
      Array<Coordinate> pts = coordList.toCoordinateArray();
      if (pts.length != 4) {
        return;
      }
      _triCoords.add(pts);
    }
  }

  List<Array<Coordinate>> getTriangles() {
    return _triCoords;
  }
}

class TriangleEdgesListVisitor implements TriangleVisitor {
  final List<Array<QuadEdge>> _triList = [];

  @override
  void visit(Array<QuadEdge> triEdges) {
    _triList.add([triEdges[0], triEdges[1], triEdges[2]].toArray());
  }

  List<Array<QuadEdge>> getTriangleEdges() {
    return _triList;
  }
}

class TriangleVertexListVisitor implements TriangleVisitor {
  List<Array<Vertex>> triList = [];

  @override
  void visit(Array<QuadEdge> triEdges) {
    triList.add([triEdges[0].orig(), triEdges[1].orig(), triEdges[2].orig()].toArray());
  }

  List<Array<Vertex>> getTriangleVertices() {
    return triList;
  }
}

class TriangleCircumcentreVisitor implements TriangleVisitor {
  @override
  void visit(Array<QuadEdge> triEdges) {
    Coordinate a = triEdges[0].orig().getCoordinate();
    Coordinate b = triEdges[1].orig().getCoordinate();
    Coordinate c = triEdges[2].orig().getCoordinate();
    Coordinate cc = Triangle.circumcentreDD(a, b, c);
    Vertex ccVertex = Vertex.of(cc);
    for (int i = 0; i < 3; i++) {
      triEdges[i].rot().setOrig(ccVertex);
    }
  }
}
