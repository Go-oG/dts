import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geomgraph/index/edge_set_intersector.dart';
import 'package:dts/src/jts/geomgraph/index/segment_intersector.dart';
import 'package:dts/src/jts/util/assert.dart';

import '../algorithm/boundary_node_rule.dart';
import '../algorithm/line_intersector.dart';
import '../algorithm/locate/point_on_geometry_locator.dart';
import '../algorithm/orientation.dart';
import '../algorithm/point_locator.dart';
import '../geom/coordinate.dart';
import '../geom/coordinate_arrays.dart';
import '../geom/geometry.dart';
import '../geom/geometry_collection.dart';
import '../geom/line_string.dart';
import '../geom/linear_ring.dart';
import '../geom/location.dart';
import '../geom/multi_line_string.dart';
import '../geom/multi_point.dart';
import '../geom/multi_polygon.dart';
import '../geom/point.dart';
import '../geom/polygon.dart';
import '../geom/polygonal.dart';
import '../geom/position.dart';
import 'edge.dart';
import 'label.dart';
import 'node.dart';
import 'planar_graph.dart';

class GeometryGraph extends PGPlanarGraph {
  static int determineBoundary(BoundaryNodeRule boundaryNodeRule, int boundaryCount) {
    return boundaryNodeRule.isInBoundary(boundaryCount) ? Location.boundary : Location.interior;
  }

  Geometry? _parentGeom;

  final Map _lineEdgeMap = {};

  BoundaryNodeRule? _boundaryNodeRule;

  bool _useBoundaryDeterminationRule = true;

  int _argIndex;

  List<Node>? _boundaryNodes;

  bool _hasTooFewPoints = false;

  Coordinate? _invalidPoint;

  PointOnGeometryLocator? _areaPtLocator;

  final PointLocator _ptLocator = PointLocator.empty();

  EdgeSetIntersector createEdgeSetIntersector() {
    return SimpleMCSweepLineIntersector();
  }

  GeometryGraph.of(int argIndex, Geometry parentGeom)
      : this(argIndex, parentGeom, BoundaryNodeRule.ogcSfsBR);

  GeometryGraph(this._argIndex, this._parentGeom, this._boundaryNodeRule) {
    if (_parentGeom != null) {
      add2(_parentGeom!);
    }
  }

  bool hasTooFewPoints() {
    return _hasTooFewPoints;
  }

  Coordinate? getInvalidPoint() {
    return _invalidPoint;
  }

  Geometry? getGeometry() {
    return _parentGeom;
  }

  BoundaryNodeRule? getBoundaryNodeRule() {
    return _boundaryNodeRule;
  }

  List<Node> getBoundaryNodes() {
    _boundaryNodes ??= nodes.getBoundaryNodes(_argIndex);
    return _boundaryNodes!;
  }

  Array<Coordinate> getBoundaryPoints() {
    final coll = getBoundaryNodes();
    Array<Coordinate> pts = Array(coll.length);
    int i = 0;
    for (var node in coll) {
      pts[i++] = node.getCoordinate().copy();
    }
    return pts;
  }

  Edge? findEdge2(LineString line) {
    return (_lineEdgeMap.get(line) as Edge?);
  }

  void computeSplitEdges(List<Edge> edgeList) {
    for (var e in edges) {
      e.eiList.addSplitEdges(edgeList);
    }
  }

  void add2(Geometry g) {
    if (g.isEmpty()) {
      return;
    }
    if (g is MultiPolygon) {
      _useBoundaryDeterminationRule = false;
    }
    if (g is Polygon) {
      addPolygon(g);
    } else if (g is LineString)
      addLineString(g);
    else if (g is Point)
      addPoint(g);
    else if (g is MultiPoint)
      addCollection(g);
    else if (g is MultiLineString)
      addCollection(g);
    else if (g is MultiPolygon)
      addCollection(g);
    else if (g is GeometryCollection)
      addCollection(g);
    else
      throw "UnsupportedOperationException";
  }

  void addCollection(GeometryCollection gc) {
    for (int i = 0; i < gc.getNumGeometries(); i++) {
      add2(gc.getGeometryN(i));
    }
  }

  void addPoint(Point p) {
    final coord = p.getCoordinate()!;
    insertPoint(_argIndex, coord, Location.interior);
  }

  void addPolygonRing(LinearRing lr, int cwLeft, int cwRight) {
    if (lr.isEmpty()) {
      return;
    }

    Array<Coordinate> coord = CoordinateArrays.removeRepeatedPoints(lr.getCoordinates());
    if (coord.length < 4) {
      _hasTooFewPoints = true;
      _invalidPoint = coord[0];
      return;
    }
    int left = cwLeft;
    int right = cwRight;
    if (Orientation.isCCW(coord)) {
      left = cwRight;
      right = cwLeft;
    }
    Edge e = Edge(coord, Label.of4(_argIndex, Location.boundary, left, right));
    _lineEdgeMap.put(lr, e);
    insertEdge(e);
    insertPoint(_argIndex, coord[0], Location.boundary);
  }

  void addPolygon(Polygon p) {
    addPolygonRing(p.getExteriorRing(), Location.exterior, Location.interior);
    for (int i = 0; i < p.getNumInteriorRing(); i++) {
      LinearRing hole = p.getInteriorRingN(i);
      addPolygonRing(hole, Location.interior, Location.exterior);
    }
  }

  void addLineString(LineString line) {
    Array<Coordinate> coord = CoordinateArrays.removeRepeatedPoints(line.getCoordinates());
    if (coord.length < 2) {
      _hasTooFewPoints = true;
      _invalidPoint = coord[0];
      return;
    }
    Edge e = Edge(coord, Label.of2(_argIndex, Location.interior));
    _lineEdgeMap.put(line, e);
    insertEdge(e);
    Assert.isTrue(coord.length >= 2, "found LineString with single point");
    insertBoundaryPoint(_argIndex, coord[0]);
    insertBoundaryPoint(_argIndex, coord[coord.length - 1]);
  }

  void addEdge(Edge e) {
    insertEdge(e);
    Array<Coordinate> coord = e.getCoordinates();
    insertPoint(_argIndex, coord[0], Location.boundary);
    insertPoint(_argIndex, coord[coord.length - 1], Location.boundary);
  }

  void addPoint2(Coordinate pt) {
    insertPoint(_argIndex, pt, Location.interior);
  }

  SegmentIntersector computeSelfNodes(LineIntersector li, bool computeRingSelfNodes) {
    SegmentIntersector si = SegmentIntersector(li, true, false);
    EdgeSetIntersector esi = createEdgeSetIntersector();
    bool isRings =
        ((_parentGeom is LinearRing) || (_parentGeom is Polygon)) || (_parentGeom is MultiPolygon);
    bool computeAllSegments = computeRingSelfNodes || (!isRings);
    esi.computeIntersections(edges, si, computeAllSegments);
    addSelfIntersectionNodes(_argIndex);
    return si;
  }

  SegmentIntersector computeEdgeIntersections(
      GeometryGraph g, LineIntersector li, bool includeProper) {
    SegmentIntersector si = SegmentIntersector(li, includeProper, true);
    si.setBoundaryNodes(getBoundaryNodes(), g.getBoundaryNodes());
    EdgeSetIntersector esi = createEdgeSetIntersector();
    esi.computeIntersections2(edges, g.edges, si);
    return si;
  }

  void insertPoint(int argIndex, Coordinate coord, int onLocation) {
    Node n = nodes.addNode(coord);
    Label? lbl = n.getLabel();
    if (lbl == null) {
      n.label = Label.of2(argIndex, onLocation);
    } else {
      lbl.setLocation(argIndex, onLocation);
    }
  }

  void insertBoundaryPoint(int argIndex, Coordinate coord) {
    Node n = nodes.addNode(coord);
    Label lbl = n.getLabel()!;
    int boundaryCount = 1;
    int loc = Location.none;
    loc = lbl.getLocation2(argIndex, Position.on);
    if (loc == Location.boundary) {
      boundaryCount++;
    }

    int newLoc = determineBoundary(_boundaryNodeRule!, boundaryCount);
    lbl.setLocation(argIndex, newLoc);
  }

  void addSelfIntersectionNodes(int argIndex) {
    for (var e in edges) {
      int eLoc = e.getLabel()!.getLocation(argIndex);
      for (var ei in e.eiList.iterator()) {
        addSelfIntersectionNode(argIndex, ei.coord, eLoc);
      }
    }
  }

  void addSelfIntersectionNode(int argIndex, Coordinate coord, int loc) {
    if (isBoundaryNode(argIndex, coord)) {
      return;
    }

    if ((loc == Location.boundary) && _useBoundaryDeterminationRule) {
      insertBoundaryPoint(argIndex, coord);
    } else {
      insertPoint(argIndex, coord, loc);
    }
  }

  int locate(Coordinate pt) {
    if ((_parentGeom is Polygonal) && (_parentGeom!.getNumGeometries() > 50)) {
      _areaPtLocator ??= IndexedPointInAreaLocator(_parentGeom);
      return _areaPtLocator!.locate(pt);
    }
    return _ptLocator.locate(pt, _parentGeom!);
  }
}
