import 'package:collection/collection.dart';
 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/area.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/index/rtree/vertex_sequence_packed_rtree.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';
import 'package:dts/src/jts/simplify/linked_line.dart';

import 'corner.dart';
import 'corner_area.dart';

class TPVWSimplifier {
  static void simplify(Array<TPVEdge> edges, CornerArea cornerArea, double removableSizeFactor) {
    TPVWSimplifier simp = TPVWSimplifier(edges);
    simp.setCornerArea(cornerArea);
    simp.setRemovableRingSizeFactor(removableSizeFactor);
    simp._simplify();
  }

  CornerArea? _cornerArea;

  double removableSizeFactor = 1.0;

  final Array<TPVEdge> _edges;

  TPVWSimplifier(this._edges);

  void setRemovableRingSizeFactor(double removableSizeFactor) {
    this.removableSizeFactor = removableSizeFactor;
  }

  void setCornerArea(CornerArea cornerArea) {
    _cornerArea = cornerArea;
  }

  void _simplify() {
    _EdgeIndex edgeIndex = _EdgeIndex();
    _add(_edges, edgeIndex);
    for (int i = 0; i < _edges.length; i++) {
      TPVEdge edge = _edges[i];
      edge.simplify(_cornerArea!, edgeIndex);
    }
  }

  void _add(Array<TPVEdge> edges, _EdgeIndex edgeIndex) {
    for (TPVEdge edge in edges) {
      edge.updateRemoved(removableSizeFactor);
      if (!edge.isRemoved()) {
        edge.init();
        edgeIndex.add(edge);
      }
    }
  }
}

class TPVEdge {
  static final int _MIN_EDGE_SIZE = 2;

  static final int _MIN_RING_SIZE = 4;

  late LinkedLine _linkedLine;

  final bool _isFreeRing;

  late int _nPts;

  Array<Coordinate> pts;

  VertexSequencePackedRtree? _vertexIndex;

  late Envelope _envelope;

  bool _isRemoved = false;

  final bool _isRemovable;

  final double _distanceTolerance;

  TPVEdge(this.pts, this._distanceTolerance, this._isFreeRing, this._isRemovable) {
    _envelope = CoordinateArrays.envelope(pts);
    _nPts = pts.length;
  }

  void updateRemoved(double removableSizeFactor) {
    if (!_isRemovable) {
      return;
    }

    double areaTolerance = _distanceTolerance * _distanceTolerance;
    _isRemoved = CoordinateArrays.isRing(pts) && (Area.ofRing(pts) < (removableSizeFactor * areaTolerance));
  }

  void init() {
    _linkedLine = LinkedLine(pts);
  }

  double getTolerance() {
    return _distanceTolerance;
  }

  bool isRemoved() {
    return _isRemoved;
  }

  Coordinate _getCoordinate(int index) {
    return pts[index];
  }

  Array<Coordinate> getCoordinates() {
    if (_isRemoved) {
      return Array(0);
    }
    return _linkedLine.getCoordinates();
  }

  Envelope getEnvelope() {
    return _envelope;
  }

  int size() {
    return _linkedLine.size();
  }

  void simplify(CornerArea cornerArea, _EdgeIndex edgeIndex) {
    if (_isRemoved) {
      return;
    }
    if (_distanceTolerance <= 0.0) {
      return;
    }

    double areaTolerance = _distanceTolerance * _distanceTolerance;
    int minEdgeSize = (_linkedLine.isRing) ? _MIN_RING_SIZE : _MIN_EDGE_SIZE;
    PriorityQueue<Corner> cornerQueue = _createQueue(areaTolerance, cornerArea);
    while ((cornerQueue.isNotEmpty) && (size() > minEdgeSize)) {
      Corner corner = cornerQueue.removeFirst();
      if (corner.isRemoved()) {
        continue;
      }
      if (corner.getArea() > areaTolerance) {
        break;
      }
      if (_isRemovableF(corner, edgeIndex)) {
        _removeCorner(corner, areaTolerance, cornerArea, cornerQueue);
      }
    }
  }

  PriorityQueue<Corner> _createQueue(double areaTolerance, CornerArea cornerArea) {
    PriorityQueue<Corner> cornerQueue = PriorityQueue<Corner>();
    int minIndex = (_linkedLine.isRing && _isFreeRing) ? 0 : 1;
    int maxIndex = _nPts - 1;
    for (int i = minIndex; i < maxIndex; i++) {
      _addCorner(i, areaTolerance, cornerArea, cornerQueue);
    }
    return cornerQueue;
  }

  void _addCorner(int i, double areaTolerance, CornerArea cornerArea, PriorityQueue<Corner> cornerQueue) {
    if (_isFreeRing || ((i != 0) && (i != (_nPts - 1)))) {
      double area = _area(i, cornerArea);
      if (area <= areaTolerance) {
        Corner corner = Corner(_linkedLine, i, area);
        cornerQueue.add(corner);
      }
    }
  }

  double _area(int index, CornerArea cornerArea) {
    Coordinate pp = _linkedLine.prevCoordinate(index);
    Coordinate p = _linkedLine.getCoordinate(index);
    Coordinate pn = _linkedLine.nextCoordinate(index);
    return cornerArea.area(pp, p, pn);
  }

  bool _isRemovableF(Corner corner, _EdgeIndex edgeIndex) {
    Envelope cornerEnv = corner.envelope();
    for (TPVEdge edge in edgeIndex.query(cornerEnv)) {
      if (_hasIntersectingVertex(corner, cornerEnv, edge)) {
        return false;
      }

      if ((edge != this) && (edge.size() == 2)) {
        Array<Coordinate> linePts = edge._linkedLine.getCoordinates();
        if (corner.isBaseline(linePts[0], linePts[1])) {
          return false;
        }
      }
    }
    return true;
  }

  bool _hasIntersectingVertex(Corner corner, Envelope cornerEnv, TPVEdge edge) {
    Array<int> result = edge._query(cornerEnv);
    for (int index in result) {
      Coordinate v = edge._getCoordinate(index);
      if (corner.isVertex2(v)) {
        continue;
      }

      if (corner.intersects(v)) {
        return true;
      }
    }
    return false;
  }

  void _initIndex() {
    _vertexIndex = VertexSequencePackedRtree(pts);
    if (CoordinateArrays.isRing(pts)) {
      _vertexIndex!.remove(pts.length - 1);
    }
  }

  Array<int> _query(Envelope cornerEnv) {
    if (_vertexIndex == null) {
      _initIndex();
    }
    return _vertexIndex!.query(cornerEnv);
  }

  void _removeCorner(Corner corner, double areaTolerance, CornerArea cornerArea, PriorityQueue<Corner> cornerQueue) {
    int index = corner.getIndex();
    int prev = _linkedLine.prev(index);
    int next = _linkedLine.next(index);
    _linkedLine.remove(index);
    _vertexIndex!.remove(index);
    _addCorner(prev, areaTolerance, cornerArea, cornerQueue);
    _addCorner(next, areaTolerance, cornerArea, cornerQueue);
  }

  @override
  String toString() {
    return _linkedLine.toString();
  }
}

class _EdgeIndex {
  STRtree<TPVEdge> index = STRtree();

  void add(TPVEdge edge) {
    index.insert(edge.getEnvelope(), edge);
  }

  List<TPVEdge> query(Envelope queryEnv) {
    return index.query(queryEnv);
  }
}
