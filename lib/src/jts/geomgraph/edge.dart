import 'dart:collection';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/quadrant.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';
import 'package:dts/src/jts/noding/oriented_coordinate_array.dart';
import 'package:dts/src/jts/util/assert.dart';

import '../algorithm/line_intersector.dart';
import '../geom/coordinate.dart';
import '../geom/envelope.dart';
import '../geom/intersection_matrix.dart';
import '../geom/position.dart';
import 'depth.dart';
import 'edge_ring.dart';
import 'geometry_graph.dart';
import 'graph_component.dart';
import 'index/monotone_chain.dart';
import 'label.dart';
import 'node.dart';

class Edge extends GraphComponent {
  static void updateIMS(Label label, IntersectionMatrix im) {
    im.setAtLeastIfValid(label.getLocation2(0, Position.on), label.getLocation2(1, Position.on), 1);
    if (label.isArea()) {
      im.setAtLeastIfValid(
          label.getLocation2(0, Position.left), label.getLocation2(1, Position.left), 2);
      im.setAtLeastIfValid(
          label.getLocation2(0, Position.right), label.getLocation2(1, Position.right), 2);
    }
  }

  Array<Coordinate> pts;

  Envelope? _env;

  late EdgeIntersectionList eiList = EdgeIntersectionList(this);

  String name = "";

  MonotoneChainEdge? _mce;

  bool _isIsolated = true;

  final Depth _depth = Depth();

  int _depthDelta = 0;

  Edge(this.pts, [Label? label]) : super(label);

  int getNumPoints() {
    return pts.length;
  }

  void setName(String name) {
    this.name = name;
  }

  Array<Coordinate> getCoordinates() {
    return pts;
  }

  Coordinate getCoordinate2(int i) {
    return pts[i];
  }

  @override
  Coordinate? getCoordinate() {
    if (pts.length > 0) {
      return pts[0];
    }
    return null;
  }

  Envelope getEnvelope() {
    if (_env == null) {
      _env = Envelope();
      for (int i = 0; i < pts.length; i++) {
        _env!.expandToIncludeCoordinate(pts[i]);
      }
    }
    return _env!;
  }

  Depth getDepth() {
    return _depth;
  }

  int getDepthDelta() {
    return _depthDelta;
  }

  void setDepthDelta(int depthDelta) {
    _depthDelta = depthDelta;
  }

  int getMaximumSegmentIndex() {
    return pts.length - 1;
  }

  EdgeIntersectionList getEdgeIntersectionList() {
    return eiList;
  }

  MonotoneChainEdge getMonotoneChainEdge() {
    _mce ??= MonotoneChainEdge(this);
    return _mce!;
  }

  bool isClosed() {
    return pts[0] == pts[pts.length - 1];
  }

  bool isCollapsed() {
    if (!label!.isArea()) return false;

    if (pts.length != 3) return false;

    if (pts[0] == pts[2]) return true;

    return false;
  }

  Edge getCollapsedEdge() {
    Array<Coordinate> newPts = Array(2);
    newPts[0] = pts[0];
    newPts[1] = pts[1];
    return Edge(newPts, Label.toLineLabel(label!));
  }

  void setIsolated(bool isIsolated) {
    _isIsolated = isIsolated;
  }

  @override
  bool isIsolated() {
    return _isIsolated;
  }

  void addIntersections(LineIntersector li, int segmentIndex, int geomIndex) {
    for (int i = 0; i < li.getIntersectionNum(); i++) {
      addIntersection(li, segmentIndex, geomIndex, i);
    }
  }

  void addIntersection(LineIntersector li, int segmentIndex, int geomIndex, int intIndex) {
    Coordinate intPt = Coordinate.of(li.getIntersection(intIndex));
    int normalizedSegmentIndex = segmentIndex;
    double dist = li.getEdgeDistance(geomIndex, intIndex);
    int nextSegIndex = normalizedSegmentIndex + 1;
    if (nextSegIndex < pts.length) {
      Coordinate nextPt = pts[nextSegIndex];
      if (intPt.equals2D(nextPt)) {
        normalizedSegmentIndex = nextSegIndex;
        dist = 0.0;
      }
    }
    eiList.add(intPt, normalizedSegmentIndex, dist);
  }

  @override
  void computeIM(IntersectionMatrix im) {
    updateIMS(label!, im);
  }

  @override
  int get hashCode {
    final int prime = 31;
    int result = 1;
    result = (prime * result) + pts.length;
    if (pts.length > 0) {
      Coordinate p0 = pts[0];
      Coordinate p1 = pts[pts.length - 1];
      if (1 == p0.compareTo(p1)) {
        p0 = pts[pts.length - 1];
        p1 = pts[0];
      }
      result = (prime * result) + p0.hashCode;
      result = (prime * result) + p1.hashCode;
    }
    return result;
  }

  bool isPointwiseEqual(Edge e) {
    if (pts.length != e.pts.length) return false;

    for (int i = 0; i < pts.length; i++) {
      if (!pts[i].equals2D(e.pts[i])) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Edge) {
      return false;
    }

    if (pts.length != other.pts.length) {
      return false;
    }

    bool isEqualForward = true;
    bool isEqualReverse = true;
    int iRev = pts.length;
    for (int i = 0; i < pts.length; i++) {
      if (!pts[i].equals2D(other.pts[i])) {
        isEqualForward = false;
      }
      if (!pts[i].equals2D(other.pts[--iRev])) {
        isEqualReverse = false;
      }
      if ((!isEqualForward) && (!isEqualReverse)) return false;
    }
    return true;
  }
}

class EdgeList {
  final List<Edge> _edges = [];

  final Map<OrientedCoordinateArray, Edge> _ocaMap = SplayTreeMap();

  void add(Edge e) {
    _edges.add(e);
    final oca = OrientedCoordinateArray(e.getCoordinates());
    _ocaMap.put(oca, e);
  }

  void addAll(List<Edge> edgeColl) {
    for (var e in edgeColl) {
      add(e);
    }
  }

  List<Edge> getEdges() {
    return _edges;
  }

  Edge? findEqualEdge(Edge e) {
    OrientedCoordinateArray oca = OrientedCoordinateArray(e.getCoordinates());
    return _ocaMap.get(oca);
  }

  ListIterator<Edge> iterator() {
    return _edges.listIterator();
  }

  Edge get(int i) {
    return _edges.get(i);
  }

  int findEdgeIndex(Edge e) {
    int i = 0;
    for (var edge in _edges) {
      if (edge == e) {
        return i;
      }
      i++;
    }
    return -1;
  }
}

class EdgeEnd implements Comparable<EdgeEnd> {
  late Edge edge;

  Label? label;

  late Node _node;

  late Coordinate _p0;

  late Coordinate _p1;

  late double _dx;

  late double _dy;

  int _quadrant = 0;

  EdgeEnd(this.edge);

  EdgeEnd.of2(this.edge, Coordinate p0, Coordinate p1, [this.label]) {
    init(p0, p1);
  }

  void init(Coordinate p0, Coordinate p1) {
    _p0 = p0;
    _p1 = p1;
    _dx = p1.x - p0.x;
    _dy = p1.y - p0.y;
    _quadrant = Quadrant.quadrant(_dx, _dy);
    Assert.isTrue2(!((_dx == 0) && (_dy == 0)), "EdgeEnd with identical endpoints found");
  }

  Edge getEdge() {
    return edge;
  }

  Label? getLabel() {
    return label;
  }

  Coordinate getCoordinate() {
    return _p0;
  }

  Coordinate getDirectedCoordinate() {
    return _p1;
  }

  int getQuadrant() {
    return _quadrant;
  }

  double getDx() {
    return _dx;
  }

  double getDy() {
    return _dy;
  }

  void setNode(Node node) {
    _node = node;
  }

  Node getNode() => _node;

  @override
  int compareTo(EdgeEnd e) {
    return compareDirection(e);
  }

  int compareDirection(EdgeEnd e) {
    if ((_dx == e._dx) && (_dy == e._dy)) {
      return 0;
    }

    if (_quadrant > e._quadrant) {
      return 1;
    }

    if (_quadrant < e._quadrant) {
      return -1;
    }

    return Orientation.index(e._p0, e._p1, _p1);
  }

  void computeLabel(BoundaryNodeRule boundaryNodeRule) {}
}

class DirectedEdge extends EdgeEnd {
  static int depthFactor(int currLocation, int nextLocation) {
    if ((currLocation == Location.exterior) && (nextLocation == Location.interior)) {
      return 1;
    } else if ((currLocation == Location.interior) && (nextLocation == Location.exterior))
      return -1;

    return 0;
  }

  bool isForward = false;

  bool _isInResult = false;

  bool _isVisited = false;

  late DirectedEdge _sym;

  DirectedEdge? _next;

  late DirectedEdge _nextMin;

  EdgeRing? _edgeRing;

  EdgeRing? _minEdgeRing;

  final Array<int> _depth = [0, -999, -999].toArray();

  DirectedEdge(super.edge, this.isForward) {
    if (isForward) {
      init(edge.getCoordinate2(0), edge.getCoordinate2(1));
    } else {
      int n = edge.getNumPoints() - 1;
      init(edge.getCoordinate2(n), edge.getCoordinate2(n - 1));
    }
    computeDirectedLabel();
  }

  @override
  Edge getEdge() {
    return edge;
  }

  void setInResult(bool isInResult) {
    _isInResult = isInResult;
  }

  bool isInResult() {
    return _isInResult;
  }

  bool isVisited() {
    return _isVisited;
  }

  void setVisited(bool isVisited) {
    _isVisited = isVisited;
  }

  void setEdgeRing(EdgeRing edgeRing) {
    _edgeRing = edgeRing;
  }

  EdgeRing? getEdgeRing() {
    return _edgeRing;
  }

  void setMinEdgeRing(EdgeRing minEdgeRing) {
    _minEdgeRing = minEdgeRing;
  }

  EdgeRing? getMinEdgeRing() {
    return _minEdgeRing;
  }

  int getDepth(int position) {
    return _depth[position];
  }

  void setDepth(int position, int depthVal) {
    if (_depth[position] != (-999)) {
      if (_depth[position] != depthVal) {
        throw TopologyException("assigned depths do not match ${getCoordinate()}");
      }
    }
    _depth[position] = depthVal;
  }

  int getDepthDelta() {
    int depthDelta = edge.getDepthDelta();
    if (!isForward) {
      depthDelta = -depthDelta;
    }

    return depthDelta;
  }

  void setVisitedEdge(bool isVisited) {
    setVisited(isVisited);
    _sym.setVisited(isVisited);
  }

  DirectedEdge getSym() {
    return _sym;
  }

  void setSym(DirectedEdge de) {
    _sym = de;
  }

  DirectedEdge? getNext() {
    return _next;
  }

  void setNext(DirectedEdge? next) {
    _next = next;
  }

  DirectedEdge getNextMin() {
    return _nextMin;
  }

  void setNextMin(DirectedEdge nextMin) {
    _nextMin = nextMin;
  }

  bool isLineEdge() {
    final label = this.label!;
    bool isLine = label.isLine(0) || label.isLine(1);
    bool isExteriorIfArea0 = (!label.isArea2(0)) || label.allPositionsEqual(0, Location.exterior);
    bool isExteriorIfArea1 = (!label.isArea2(1)) || label.allPositionsEqual(1, Location.exterior);
    return (isLine && isExteriorIfArea0) && isExteriorIfArea1;
  }

  bool isInteriorAreaEdge() {
    final label = this.label!;
    bool isInteriorAreaEdge = true;
    for (int i = 0; i < 2; i++) {
      if (!((label.isArea2(i) && (label.getLocation2(i, Position.left) == Location.interior)) &&
          (label.getLocation2(i, Position.right) == Location.interior))) {
        isInteriorAreaEdge = false;
      }
    }
    return isInteriorAreaEdge;
  }

  void computeDirectedLabel() {
    label = Label(edge.label!);
    if (!isForward) label!.flip();
  }

  void setEdgeDepths(int position, int depth) {
    int depthDelta = getEdge().getDepthDelta();
    if (!isForward) depthDelta = -depthDelta;

    int directionFactor = 1;
    if (position == Position.left) directionFactor = -1;

    int oppositePos = Position.opposite(position);
    int delta = depthDelta * directionFactor;
    int oppositeDepth = depth + delta;
    setDepth(position, depth);
    setDepth(oppositePos, oppositeDepth);
  }
}

abstract class EdgeEndStar {
  //<EdgeEnd,EdgeEnd>
  Map<EdgeEnd, Object> edgeMap = SplayTreeMap();

  List<EdgeEnd>? edgeList;

  final Array<int> _ptInAreaLocation = [Location.none, Location.none].toArray();

  void insert(EdgeEnd e);

  void insertEdgeEnd(EdgeEnd e, Object obj) {
    edgeMap.put(e, obj);
    edgeList = null;
  }

  Coordinate? getCoordinate() {
    final edgeList = this.edgeList;
    if (edgeList == null || edgeList.isEmpty) {
      return null;
    }
    return edgeList.first.getCoordinate();
  }

  int getDegree() {
    return edgeMap.length;
  }

  List<EdgeEnd> iterator() {
    return getEdges();
  }

  List<EdgeEnd> getEdges() {
    edgeList ??= [];
    return edgeList!;
  }

  EdgeEnd getNextCW(EdgeEnd ee) {
    getEdges();
    int i = edgeList!.indexOf(ee);
    int iNextCW = i - 1;
    if (i == 0) {
      iNextCW = edgeList!.length - 1;
    }

    return (edgeList!.get(iNextCW));
  }

  void computeLabelling(Array<GeometryGraph> geomGraph) {
    computeEdgeEndLabels(geomGraph[0].getBoundaryNodeRule()!);
    propagateSideLabels(0);
    propagateSideLabels(1);
    Array<bool> hasDimensionalCollapseEdge = [false, false].toArray();
    for (var e in edgeList!) {
      Label label = e.getLabel()!;
      for (int geomi = 0; geomi < 2; geomi++) {
        if (label.isLine(geomi) && (label.getLocation(geomi) == Location.boundary)) {
          hasDimensionalCollapseEdge[geomi] = true;
        }
      }
    }

    for (var e in edgeList!) {
      Label label = e.getLabel()!;
      for (int geomi = 0; geomi < 2; geomi++) {
        if (label.isAnyNull(geomi)) {
          int loc = Location.none;
          if (hasDimensionalCollapseEdge[geomi]) {
            loc = Location.exterior;
          } else {
            Coordinate p = e.getCoordinate();
            loc = getLocation(geomi, p, geomGraph);
          }
          label.setAllLocationsIfNull2(geomi, loc);
        }
      }
    }
  }

  void computeEdgeEndLabels(BoundaryNodeRule boundaryNodeRule) {
    for (var ee in edgeList!) {
      ee.computeLabel(boundaryNodeRule);
    }
  }

  int getLocation(int geomIndex, Coordinate p, Array<GeometryGraph> geom) {
    if (_ptInAreaLocation[geomIndex] == Location.none) {
      _ptInAreaLocation[geomIndex] =
          SimplePointInAreaLocator.locateS(p, geom[geomIndex].getGeometry()!);
    }
    return _ptInAreaLocation[geomIndex];
  }

  bool isAreaLabelsConsistent(GeometryGraph geomGraph) {
    computeEdgeEndLabels(geomGraph.getBoundaryNodeRule()!);
    return checkAreaLabelsConsistent(0);
  }

  bool checkAreaLabelsConsistent(int geomIndex) {
    final edges = getEdges();
    if (edges.isEmpty) return true;

    int lastEdgeIndex = edges.length - 1;
    Label startLabel = edges.get(lastEdgeIndex).getLabel()!;
    int startLoc = startLabel.getLocation2(geomIndex, Position.left);
    Assert.isTrue2(startLoc != Location.none, "Found unlabelled area edge");
    int currLoc = startLoc;

    for (var e in edgeList!) {
      Label label = e.getLabel()!;
      Assert.isTrue2(label.isArea2(geomIndex), "Found non-area edge");
      int leftLoc = label.getLocation2(geomIndex, Position.left);
      int rightLoc = label.getLocation2(geomIndex, Position.right);
      if (leftLoc == rightLoc) {
        return false;
      }
      if (rightLoc != currLoc) {
        return false;
      }
      currLoc = leftLoc;
    }
    return true;
  }

  void propagateSideLabels(int geomIndex) {
    int startLoc = Location.none;
    for (var e in edgeList!) {
      Label label = e.getLabel()!;
      if (label.isArea2(geomIndex) &&
          (label.getLocation2(geomIndex, Position.left) != Location.none)) {
        startLoc = label.getLocation2(geomIndex, Position.left);
      }
    }
    if (startLoc == Location.none) return;

    int currLoc = startLoc;
    for (var e in edgeList!) {
      Label label = e.getLabel()!;
      if (label.getLocation2(geomIndex, Position.on) == Location.none) {
        label.setLocation2(geomIndex, Position.on, currLoc);
      }

      if (label.isArea2(geomIndex)) {
        int leftLoc = label.getLocation2(geomIndex, Position.left);
        int rightLoc = label.getLocation2(geomIndex, Position.right);
        if (rightLoc != Location.none) {
          if (rightLoc != currLoc)
            throw TopologyException("side location conflict ${e.getCoordinate()}");

          if (leftLoc == Location.none) {
            Assert.shouldNeverReachHere2("found single null side (at ${e.getCoordinate()})");
          }
          currLoc = leftLoc;
        } else {
          Assert.isTrue2(label.getLocation2(geomIndex, Position.left) == Location.none,
              "found single null side");
          label.setLocation2(geomIndex, Position.right, currLoc);
          label.setLocation2(geomIndex, Position.left, currLoc);
        }
      }
    }
  }

  int findIndex(EdgeEnd eSearch) {
    iterator();
    int i = 0;
    for (var e in edgeList!) {
      if (e == eSearch) return i;
      i++;
    }
    return -1;
  }
}

class DirectedEdgeStar extends EdgeEndStar {
  List<DirectedEdge>? _resultAreaEdgeList;

  Label? _label;

  @override
  void insert(covariant DirectedEdge ee) {
    insertEdgeEnd(ee, ee);
  }

  Label? getLabel() {
    return _label;
  }

  int getOutgoingDegree() {
    int degree = 0;

    for (var it in iterator()) {
      DirectedEdge de = it as DirectedEdge;
      if (de.isInResult()) {
        degree++;
      }
    }
    return degree;
  }

  int getOutgoingDegree2(EdgeRing er) {
    int degree = 0;
    for (var it in iterator()) {
      DirectedEdge de = it as DirectedEdge;
      if (de.getEdgeRing() == er) {
        degree++;
      }
    }
    return degree;
  }

  DirectedEdge? getRightmostEdge() {
    List<EdgeEnd> edges = getEdges();
    int size = edges.length;
    if (size < 1) return null;

    DirectedEdge de0 = edges.first as DirectedEdge;
    if (size == 1) return de0;

    DirectedEdge deLast = edges.last as DirectedEdge;
    int quad0 = de0.getQuadrant();
    int quad1 = deLast.getQuadrant();
    if (Quadrant.isNorthern(quad0) && Quadrant.isNorthern(quad1)) {
      return de0;
    } else if ((!Quadrant.isNorthern(quad0)) && (!Quadrant.isNorthern(quad1))) {
      return deLast;
    } else {
      if (de0.getDy() != 0) {
        return de0;
      } else if (deLast.getDy() != 0) {
        return deLast;
      }
    }

    Assert.shouldNeverReachHere2("found two horizontal edges incident on node");
    return null;
  }

  @override
  void computeLabelling(Array<GeometryGraph> geom) {
    super.computeLabelling(geom);
    _label = Label.of(Location.none);
    for (var ee in iterator()) {
      Edge e = ee.getEdge();
      Label eLabel = e.getLabel()!;
      for (int i = 0; i < 2; i++) {
        int eLoc = eLabel.getLocation(i);
        if ((eLoc == Location.interior) || (eLoc == Location.boundary)) {
          _label!.setLocation(i, Location.interior);
        }
      }
    }
  }

  void mergeSymLabels() {
    for (var it in iterator()) {
      DirectedEdge de = it as DirectedEdge;
      Label label = de.getLabel()!;
      label.merge(de.getSym().getLabel()!);
    }
  }

  void updateLabelling(Label nodeLabel) {
    for (var it in iterator()) {
      DirectedEdge de = (it as DirectedEdge);
      Label label = de.getLabel()!;
      label.setAllLocationsIfNull2(0, nodeLabel.getLocation(0));
      label.setAllLocationsIfNull2(1, nodeLabel.getLocation(1));
    }
  }

  List getResultAreaEdges() {
    if (_resultAreaEdgeList != null) return _resultAreaEdgeList!;

    _resultAreaEdgeList = [];
    for (var it in iterator()) {
      DirectedEdge de = it as DirectedEdge;
      if (de.isInResult() || de.getSym().isInResult()) _resultAreaEdgeList!.add(de);
    }
    return _resultAreaEdgeList!;
  }

  static const int _SCANNING_FOR_INCOMING = 1;

  static const int _LINKING_TO_OUTGOING = 2;

  void linkResultDirectedEdges() {
    getResultAreaEdges();
    DirectedEdge? firstOut;
    DirectedEdge? incoming;
    int state = _SCANNING_FOR_INCOMING;
    for (int i = 0; i < _resultAreaEdgeList!.length; i++) {
      DirectedEdge nextOut = _resultAreaEdgeList![i];
      DirectedEdge nextIn = nextOut.getSym();
      if (!nextOut.getLabel()!.isArea()) continue;

      if ((firstOut == null) && nextOut.isInResult()) firstOut = nextOut;

      switch (state) {
        case _SCANNING_FOR_INCOMING:
          if (!nextIn.isInResult()) continue;

          incoming = nextIn;
          state = _LINKING_TO_OUTGOING;
          break;
        case _LINKING_TO_OUTGOING:
          if (!nextOut.isInResult()) continue;

          incoming!.setNext(nextOut);
          state = _SCANNING_FOR_INCOMING;
          break;
      }
    }
    if (state == _LINKING_TO_OUTGOING) {
      if (firstOut == null) throw TopologyException("no outgoing dirEdge found", getCoordinate());
      Assert.isTrue2(firstOut.isInResult(), "unable to link last incoming dirEdge");
      incoming!.setNext(firstOut);
    }
  }

  void linkMinimalDirectedEdges(EdgeRing er) {
    DirectedEdge? firstOut;
    DirectedEdge? incoming;
    int state = _SCANNING_FOR_INCOMING;
    for (int i = _resultAreaEdgeList!.length - 1; i >= 0; i--) {
      DirectedEdge nextOut = (_resultAreaEdgeList![i]);
      DirectedEdge nextIn = nextOut.getSym();
      if ((firstOut == null) && (nextOut.getEdgeRing() == er)) firstOut = nextOut;

      switch (state) {
        case _SCANNING_FOR_INCOMING:
          if (nextIn.getEdgeRing() != er) continue;

          incoming = nextIn;
          state = _LINKING_TO_OUTGOING;
          break;
        case _LINKING_TO_OUTGOING:
          if (nextOut.getEdgeRing() != er) continue;

          incoming!.setNextMin(nextOut);
          state = _SCANNING_FOR_INCOMING;
          break;
      }
    }
    if (state == _LINKING_TO_OUTGOING) {
      Assert.isTrue2(firstOut != null, "found null for first outgoing dirEdge");
      Assert.isTrue2(firstOut!.getEdgeRing() == er, "unable to link last incoming dirEdge");
      incoming!.setNextMin(firstOut);
    }
  }

  void linkAllDirectedEdges() {
    getEdges();
    DirectedEdge? prevOut;
    DirectedEdge? firstIn;
    for (int i = edgeList!.length - 1; i >= 0; i--) {
      DirectedEdge nextOut = edgeList![i] as DirectedEdge;
      DirectedEdge nextIn = nextOut.getSym();
      firstIn ??= nextIn;

      if (prevOut != null) nextIn.setNext(prevOut);

      prevOut = nextOut;
    }
    firstIn!.setNext(prevOut);
  }

  void findCoveredLineEdges() {
    int startLoc = Location.none;
    for (var it in iterator()) {
      DirectedEdge nextOut = it as DirectedEdge;
      DirectedEdge nextIn = nextOut.getSym();
      if (!nextOut.isLineEdge()) {
        if (nextOut.isInResult()) {
          startLoc = Location.interior;
          break;
        }
        if (nextIn.isInResult()) {
          startLoc = Location.exterior;
          break;
        }
      }
    }
    if (startLoc == Location.none) return;

    int currLoc = startLoc;
    for (var it in iterator()) {
      DirectedEdge nextOut = it as DirectedEdge;
      DirectedEdge nextIn = nextOut.getSym();
      if (nextOut.isLineEdge()) {
        nextOut.getEdge().setCovered(currLoc == Location.interior);
      } else {
        if (nextOut.isInResult()) currLoc = Location.exterior;

        if (nextIn.isInResult()) currLoc = Location.interior;
      }
    }
  }

  void computeDepths(DirectedEdge de) {
    int edgeIndex = findIndex(de);
    int startDepth = de.getDepth(Position.left);
    int targetLastDepth = de.getDepth(Position.right);
    int nextDepth = computeDepths2(edgeIndex + 1, edgeList!.length, startDepth);
    int lastDepth = computeDepths2(0, edgeIndex, nextDepth);
    if (lastDepth != targetLastDepth)
      throw TopologyException("depth mismatch at ${de.getCoordinate()}");
  }

  int computeDepths2(int startIndex, int endIndex, int startDepth) {
    int currDepth = startDepth;
    for (int i = startIndex; i < endIndex; i++) {
      DirectedEdge nextDe = edgeList![i] as DirectedEdge;
      nextDe.setEdgeDepths(Position.right, currDepth);
      currDepth = nextDe.getDepth(Position.left);
    }
    return currDepth;
  }
}

class EdgeIntersection implements Comparable<EdgeIntersection> {
  Coordinate coord;
  int segmentIndex;
  double dist;

  EdgeIntersection(this.coord, this.segmentIndex, this.dist);

  Coordinate getCoordinate() {
    return coord;
  }

  int getSegmentIndex() {
    return segmentIndex;
  }

  double getDistance() {
    return dist;
  }

  @override
  int compareTo(EdgeIntersection other) {
    return compare(other.segmentIndex, other.dist);
  }

  int compare(int segmentIndex, double dist) {
    if (this.segmentIndex < segmentIndex) return -1;

    if (this.segmentIndex > segmentIndex) return 1;

    if (this.dist < dist) return -1;

    if (this.dist > dist) return 1;

    return 0;
  }

  bool isEndPoint(int maxSegmentIndex) {
    if ((segmentIndex == 0) && (dist == 0.0)) return true;

    if (segmentIndex == maxSegmentIndex) return true;

    return false;
  }
}

class EdgeIntersectionList {
  final Map<EdgeIntersection, EdgeIntersection> _nodeMap = SplayTreeMap();

  Edge edge;

  EdgeIntersectionList(this.edge);

  EdgeIntersection add(Coordinate intPt, int segmentIndex, double dist) {
    final eiNew = EdgeIntersection(intPt, segmentIndex, dist);
    final ei = _nodeMap.get(eiNew);
    if (ei != null) {
      return ei;
    }
    _nodeMap.put(eiNew, eiNew);
    return eiNew;
  }

  Iterable<EdgeIntersection> iterator() {
    return _nodeMap.values;
  }

  bool isIntersection(Coordinate pt) {
    for (var ei in _nodeMap.values) {
      if (ei.coord == pt) return true;
    }
    return false;
  }

  void addEndpoints() {
    int maxSegIndex = edge.pts.length - 1;
    add(edge.pts[0], 0, 0.0);
    add(edge.pts[maxSegIndex], maxSegIndex, 0.0);
  }

  void addSplitEdges(List<Edge> edgeList) {
    addEndpoints();
    final list = _nodeMap.values.toList();
    EdgeIntersection eiPrev = list.first;
    for (int i = 1; i < list.length; i++) {
      final ei = list[i];
      final newEdge = createSplitEdge(eiPrev, ei);
      edgeList.add(newEdge);
      eiPrev = ei;
    }
  }

  Edge createSplitEdge(EdgeIntersection ei0, EdgeIntersection ei1) {
    int npts = (ei1.segmentIndex - ei0.segmentIndex) + 2;
    Coordinate lastSegStartPt = edge.pts[ei1.segmentIndex];
    bool useIntPt1 = (ei1.dist > 0.0) || (!ei1.coord.equals2D(lastSegStartPt));
    if (!useIntPt1) {
      npts--;
    }
    Array<Coordinate> pts = Array(npts);
    int ipt = 0;
    pts[ipt++] = Coordinate.of(ei0.coord);
    for (int i = ei0.segmentIndex + 1; i <= ei1.segmentIndex; i++) {
      pts[ipt++] = edge.pts[i];
    }
    if (useIntPt1) pts[ipt] = ei1.coord;

    return Edge(pts, Label(edge.label!));
  }
}
