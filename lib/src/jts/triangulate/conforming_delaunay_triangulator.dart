import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/convex_hull.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/index/kd_tree.dart';
import 'package:dts/src/jts/triangulate/quadedge/last_found_quad_edge_locator.dart';
import 'package:dts/src/jts/triangulate/quadedge/quad_edge_subdivision.dart';
import 'package:dts/src/jts/triangulate/quadedge/vertex.dart';

import 'constraint_enforcement_exception.dart';
import 'constraint_split_point_finder.dart';
import 'constraint_vertex.dart';
import 'constraint_vertex_factory.dart';
import 'incremental_delaunay_triangulator.dart';
import 'non_encroaching_split_point_finder.dart';
import 'segment.dart';

class ConformingDelaunayTriangulator {
  static Envelope computeVertexEnvelope(List<Vertex> vertices) {
    Envelope env = Envelope();
    for (Iterator i = vertices.iterator; i.moveNext();) {
      env.expandToIncludeCoordinate(i.current.getCoordinate());
    }
    return env;
  }

  late List<Vertex> _initialVertices;

  late List<Vertex> _segVertices;

  List<Segment> _segments = [];

  late QuadEdgeSubdivision subdiv;

  late IncrementalDelaunayTriangulator _incDel;

  late Geometry _convexHull;

  ConstraintSplitPointFinder _splitFinder = NonEncroachingSplitPointFinder();

  late KdTree _kdt;

  ConstraintVertexFactory? _vertexFactory;

  late Envelope _computeAreaEnv;

  late Coordinate _splitPt;

  double tolerance;

  ConformingDelaunayTriangulator(List<Vertex> initialVertices, this.tolerance) {
    _initialVertices = List.from(initialVertices);
    _kdt = KdTree(tolerance);
  }

  void setConstraints(List<Segment> segments, List<Vertex> segVertices) {
    _segments = segments;
    _segVertices = segVertices;
  }

  void setSplitPointFinder(ConstraintSplitPointFinder splitFinder) {
    _splitFinder = splitFinder;
  }

  double getTolerance() {
    return tolerance;
  }

  ConstraintVertexFactory? getVertexFactory() {
    return _vertexFactory;
  }

  void setVertexFactory(ConstraintVertexFactory vertexFactory) {
    _vertexFactory = vertexFactory;
  }

  QuadEdgeSubdivision getSubdivision() {
    return subdiv;
  }

  KdTree getKDT() {
    return _kdt;
  }

  List getInitialVertices() {
    return _initialVertices;
  }

  List getConstraintSegments() {
    return _segments;
  }

  Geometry getConvexHull() {
    return _convexHull;
  }

  void computeBoundingBox() {
    Envelope vertexEnv = computeVertexEnvelope(_initialVertices);
    Envelope segEnv = computeVertexEnvelope(_segVertices);
    Envelope allPointsEnv = Envelope.from(vertexEnv);
    allPointsEnv.expandToInclude(segEnv);
    double deltaX = allPointsEnv.width * 0.2;
    double deltaY = allPointsEnv.height * 0.2;
    double delta = Math.maxD(deltaX, deltaY);
    _computeAreaEnv = Envelope.from(allPointsEnv);
    _computeAreaEnv.expandBy(delta);
  }

  void computeConvexHull() {
    GeometryFactory fact = GeometryFactory.empty();
    Array<Coordinate> coords = getPointArray();
    ConvexHull hull = ConvexHull(coords, fact);
    _convexHull = hull.getConvexHull();
  }

  Array<Coordinate> getPointArray() {
    Array<Coordinate> pts = Array(_initialVertices.size + _segVertices.size);
    int index = 0;
    for (var i = _initialVertices.iterator; i.moveNext();) {
      pts[index++] = i.current.getCoordinate();
    }
    for (var i2 = _segVertices.iterator; i2.moveNext();) {
      pts[index++] = i2.current.getCoordinate();
    }
    return pts;
  }

  ConstraintVertex createVertex(Coordinate p) {
    ConstraintVertex v;
    if (_vertexFactory != null) {
      v = _vertexFactory!.createVertex(p, null);
    } else {
      v = ConstraintVertex(p);
    }

    return v;
  }

  ConstraintVertex createVertex2(Coordinate p, Segment seg) {
    ConstraintVertex v;
    if (_vertexFactory != null) {
      v = _vertexFactory!.createVertex(p, seg);
    } else {
      v = ConstraintVertex(p);
    }

    v.setOnConstraint(true);
    return v;
  }

  void insertSites(List<Vertex> vertices) {
    for (var i = vertices.iterator; i.moveNext();) {
      insertSite2(i.current as ConstraintVertex);
    }
  }

  ConstraintVertex insertSite2(ConstraintVertex v) {
    KdNode kdnode = _kdt.insert2(v.getCoordinate(), v);
    if (!kdnode.isRepeated()) {
      _incDel.insertSite(v);
    } else {
      ConstraintVertex snappedV = (kdnode.getData() as ConstraintVertex);
      snappedV.merge(v);
      return snappedV;
    }
    return v;
  }

  void insertSite(Coordinate p) {
    insertSite2(createVertex(p));
  }

  void formInitialDelaunay() {
    computeBoundingBox();
    subdiv = QuadEdgeSubdivision(_computeAreaEnv, tolerance);
    subdiv.setLocator(LastFoundQuadEdgeLocator(subdiv));
    _incDel = IncrementalDelaunayTriangulator(subdiv);
    insertSites(_initialVertices);
  }

  static const int _MAX_SPLIT_ITER = 99;

  void enforceConstraints() {
    addConstraintVertices();
    int count = 0;
    int splits = 0;
    do {
      splits = enforceGabriel(_segments);
      count++;
    } while ((splits > 0) && (count < _MAX_SPLIT_ITER));
    if (count == _MAX_SPLIT_ITER) {
      throw ConstraintEnforcementException(
        "Too many splitting iterations while enforcing constraints.  Last split point was at: ",
        _splitPt,
      );
    }
  }

  void addConstraintVertices() {
    computeConvexHull();
    insertSites(_segVertices);
  }

  int enforceGabriel(List<Segment> segsToInsert) {
    List<Segment> newSegments = [];
    int splits = 0;
    List<Segment> segsToRemove = [];
    for (var i = segsToInsert.iterator; i.moveNext();) {
      Segment seg = i.current;
      Coordinate? encroachPt = findNonGabrielPoint(seg);
      if (encroachPt == null) continue;

      _splitPt = _splitFinder.findSplitPoint(seg, encroachPt);
      ConstraintVertex splitVertex = createVertex2(_splitPt, seg);
      insertSite2(splitVertex);

      Segment s1 = Segment.of2(
        seg.getStartX(),
        seg.getStartY(),
        seg.getStartZ(),
        splitVertex.getX(),
        splitVertex.getY(),
        splitVertex.getZ(),
        seg.data,
      );
      Segment s2 = Segment.of2(
        splitVertex.getX(),
        splitVertex.getY(),
        splitVertex.getZ(),
        seg.getEndX(),
        seg.getEndY(),
        seg.getEndZ(),
        seg.data,
      );
      newSegments.add(s1);
      newSegments.add(s2);
      segsToRemove.add(seg);
      splits = splits + 1;
    }

    segsToInsert.removeAll(segsToRemove);
    segsToInsert.addAll(newSegments);
    return splits;
  }

  Coordinate? findNonGabrielPoint(Segment seg) {
    Coordinate p = seg.getStart();
    Coordinate q = seg.getEnd();
    Coordinate midPt = Coordinate((p.x + q.x) / 2.0, (p.y + q.y) / 2.0);
    double segRadius = p.distance(midPt);
    Envelope env = Envelope.fromCoordinate(midPt);
    env.expandBy(segRadius);
    List result = _kdt.query2(env);

    Coordinate? closestNonGabriel;
    double minDist = double.maxFinite;
    for (var i = result.iterator; i.moveNext();) {
      KdNode nextNode = i.current as KdNode;
      Coordinate testPt = nextNode.getCoordinate();
      if (testPt.equals2D(p) || testPt.equals2D(q)) continue;

      double testRadius = midPt.distance(testPt);
      if (testRadius < segRadius) {
        double testDist = testRadius;
        if ((closestNonGabriel == null) || (testDist < minDist)) {
          closestNonGabriel = testPt;
          minDist = testDist;
        }
      }
    }
    return closestNonGabriel;
  }
}
