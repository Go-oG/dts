import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/triangle.dart';
import 'package:dts/src/jts/index/rtree/vertex_sequence_packed_rtree.dart';

import 'linked_ring.dart';
import 'ring_hull_index.dart';

class RingHull {
  final LinearRing _inputRing;

  int _targetVertexNum = -1;

  double _targetAreaDelta = -1;

  late LinkedRing _vertexRing;

  double _areaDelta = 0;

  late VertexSequencePackedRtree vertexIndex;

  late PriorityQueue<RingHullCorner> _cornerQueue;

  RingHull(this._inputRing, bool isOuter) {
    init(_inputRing.getCoordinates(), isOuter);
  }

  void setMinVertexNum(int minVertexNum) {
    _targetVertexNum = minVertexNum;
  }

  void setMaxAreaDelta(double maxAreaDelta) {
    _targetAreaDelta = maxAreaDelta;
  }

  Envelope getEnvelope() {
    return _inputRing.getEnvelopeInternal();
  }

  VertexSequencePackedRtree getVertexIndex() {
    return vertexIndex;
  }

  LinearRing getHull(RingHullIndex? hullIndex) {
    compute(hullIndex);
    Array<Coordinate> hullPts = _vertexRing.getCoordinates();
    return _inputRing.factory.createLinearRings(hullPts);
  }

  void init(Array<Coordinate> ring, bool isOuter) {
    bool orientCW = isOuter;
    if (orientCW == Orientation.isCCW(ring)) {
      ring = ring.copy();
      CoordinateArrays.reverse(ring);
    }
    _vertexRing = LinkedRing(ring);
    vertexIndex = VertexSequencePackedRtree(ring);
    vertexIndex.remove(ring.length - 1);
    _cornerQueue = PriorityQueue<RingHullCorner>();
    for (int i = 0; i < _vertexRing.size; i++) {
      addCorner(i, _cornerQueue);
    }
  }

  void addCorner(int i, PriorityQueue<RingHullCorner> cornerQueue) {
    if (isConvex(_vertexRing, i)) {
      return;
    }

    RingHullCorner corner =
        RingHullCorner(i, _vertexRing.getPrev(i), _vertexRing.getNext(i), area(_vertexRing, i));
    cornerQueue.add(corner);
  }

  static bool isConvex(LinkedRing vertexRing, int index) {
    Coordinate pp = vertexRing.prevCoordinate(index);
    Coordinate p = vertexRing.getCoordinate(index);
    Coordinate pn = vertexRing.nextCoordinate(index);
    return Orientation.clockwise == Orientation.index(pp, p, pn);
  }

  static double area(LinkedRing vertexRing, int index) {
    Coordinate pp = vertexRing.prevCoordinate(index);
    Coordinate p = vertexRing.getCoordinate(index);
    Coordinate pn = vertexRing.nextCoordinate(index);
    return Triangle.area2(pp, p, pn);
  }

  void compute(RingHullIndex? hullIndex) {
    while ((_cornerQueue.isNotEmpty) && (_vertexRing.size > 3)) {
      RingHullCorner corner = _cornerQueue.removeFirst();
      if (corner.isRemoved(_vertexRing)) continue;

      if (isAtTarget(corner)) return;

      if (isRemovable(corner, hullIndex)) {
        removeCorner(corner, _cornerQueue);
      }
    }
  }

  bool isAtTarget(RingHullCorner corner) {
    if (_targetVertexNum >= 0) {
      return _vertexRing.size < _targetVertexNum;
    }
    if (_targetAreaDelta >= 0) {
      return (_areaDelta + corner.getArea()) > _targetAreaDelta;
    }
    return true;
  }

  void removeCorner(RingHullCorner corner, PriorityQueue<RingHullCorner> cornerQueue) {
    int index = corner.getIndex();
    int prev = _vertexRing.getPrev(index);
    int next = _vertexRing.getNext(index);
    _vertexRing.remove(index);
    vertexIndex.remove(index);
    _areaDelta += corner.getArea();
    addCorner(prev, cornerQueue);
    addCorner(next, cornerQueue);
  }

  bool isRemovable(RingHullCorner corner, RingHullIndex? hullIndex) {
    Envelope cornerEnv = corner.envelope(_vertexRing);
    if (hasIntersectingVertex(corner, cornerEnv, this)) return false;

    if (hullIndex == null) return true;

    for (RingHull hull in hullIndex.query(cornerEnv)) {
      if (hull == this) continue;

      if (hasIntersectingVertex(corner, cornerEnv, hull)) return false;
    }
    return true;
  }

  bool hasIntersectingVertex(RingHullCorner corner, Envelope cornerEnv, RingHull hull) {
    Array<int> result = hull.query(cornerEnv);
    for (int i = 0; i < result.length; i++) {
      int index = result[i];
      if ((hull == this) && corner.isVertex(index)) continue;

      Coordinate v = hull.getCoordinate(index);
      if (corner.intersects(v, _vertexRing)) return true;
    }
    return false;
  }

  Coordinate getCoordinate(int index) {
    return _vertexRing.getCoordinate(index);
  }

  Array<int> query(Envelope cornerEnv) {
    return vertexIndex.query(cornerEnv);
  }

  void queryHull(Envelope queryEnv, List<Coordinate> pts) {
    Array<int> result = vertexIndex.query(queryEnv);
    for (int i = 0; i < result.length; i++) {
      int index = result[i];
      if (!_vertexRing.hasCoordinate(index)) continue;

      Coordinate v = _vertexRing.getCoordinate(index);
      pts.add(v);
    }
  }

  Polygon toGeometry() {
    GeometryFactory fact = GeometryFactory();
    Array<Coordinate> coords = _vertexRing.getCoordinates();
    return fact.createPolygon(fact.createLinearRings(coords));
  }
}

class RingHullCorner implements Comparable<RingHullCorner> {
  int index;

  int prev;

  int next;

  double area;

  RingHullCorner(this.index, this.prev, this.next, this.area);

  bool isVertex(int index) {
    return ((index == this.index) || (index == prev)) || (index == next);
  }

  int getIndex() {
    return index;
  }

  double getArea() {
    return area;
  }

  @override
  int compareTo(RingHullCorner o) {
    return Double.compare(area, o.area);
  }

  Envelope envelope(LinkedRing ring) {
    Coordinate pp = ring.getCoordinate(prev);
    Coordinate p = ring.getCoordinate(index);
    Coordinate pn = ring.getCoordinate(next);
    Envelope env = Envelope.of(pp, pn);
    env.expandToIncludeCoordinate(p);
    return env;
  }

  bool intersects(Coordinate v, LinkedRing ring) {
    Coordinate pp = ring.getCoordinate(prev);
    Coordinate p = ring.getCoordinate(index);
    Coordinate pn = ring.getCoordinate(next);
    return Triangle.intersects(pp, p, pn, v);
  }

  bool isRemoved(LinkedRing ring) {
    return (ring.getPrev(index) != prev) || (ring.getNext(index) != next);
  }

  LineString toLineString(LinkedRing ring) {
    Coordinate pp = ring.getCoordinate(prev);
    Coordinate p = ring.getCoordinate(index);
    Coordinate pn = ring.getCoordinate(next);
    return GeometryFactory()
        .createLineString2([safeCoord(pp), safeCoord(p), safeCoord(pn)].toArray());
  }

  static Coordinate safeCoord(Coordinate? p) {
    if (p == null) {
      return Coordinate(double.nan, double.nan);
    }

    return p;
  }
}
