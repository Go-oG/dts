import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';

class CoverageEdge {
  static const int RING_COUNT_INNER = 2;
  static const int RING_COUNT_OUTER = 1;

  static CoverageEdge createEdge(Array<Coordinate> ring, bool isPrimary) {
    Array<Coordinate> pts = _extractEdgePoints(ring, 0, ring.length - 1);
    CoverageEdge edge = CoverageEdge(pts, isPrimary, true);
    return edge;
  }

  static CoverageEdge createEdge2(Array<Coordinate> ring, int start, int end, bool isPrimary) {
    Array<Coordinate> pts = _extractEdgePoints(ring, start, end);
    CoverageEdge edge = CoverageEdge(pts, isPrimary, false);
    return edge;
  }

  static Array<Coordinate> _extractEdgePoints(Array<Coordinate> ring, int start, int end) {
    int size = (start < end) ? (end - start) + 1 : (ring.length - start) + end;
    Array<Coordinate> pts = Array<Coordinate>(size);
    int iring = start;
    for (int i = 0; i < size; i++) {
      pts[i] = ring[iring].copy();
      iring += 1;
      if (iring >= ring.length) {
        iring = 1;
      }
    }
    return pts;
  }

  static LineSegment key(Array<Coordinate> ring) {
    int indexLow = 0;
    for (int i = 1; i < (ring.length - 1); i++) {
      if (ring[indexLow].compareTo(ring[i]) < 0) {
        indexLow = i;
      }
    }
    Coordinate key0 = ring[indexLow];
    Coordinate adj0 = _findDistinctPoint(ring, indexLow, true, key0);
    Coordinate adj1 = _findDistinctPoint(ring, indexLow, false, key0);
    Coordinate key1 = (adj0.compareTo(adj1) < 0) ? adj0 : adj1;
    return LineSegment(key0, key1);
  }

  static LineSegment key2(Array<Coordinate> ring, int start, int end) {
    Coordinate end0 = ring[start];
    Coordinate end1 = ring[end];
    bool isForward = 0 > end0.compareTo(end1);
    Coordinate key0;
    Coordinate key1;
    if (isForward) {
      key0 = end0;
      key1 = _findDistinctPoint(ring, start, true, key0);
    } else {
      key0 = end1;
      key1 = _findDistinctPoint(ring, end, false, key0);
    }
    return LineSegment(key0, key1);
  }

  static Coordinate _findDistinctPoint(
      Array<Coordinate> pts, int index, bool isForward, Coordinate pt) {
    int inc = (isForward) ? 1 : -1;
    int i = index;
    do {
      if (!pts[i].equals2D(pt)) {
        return pts[i];
      }
      i += inc;
      if (i < 0) {
        i = pts.length - 1;
      } else if (i > (pts.length - 1)) {
        i = 0;
      }
    } while (i != index);
    throw ("Edge does not contain distinct points");
  }

  late Array<Coordinate> _pts;

  int _ringCount = 0;

  bool _isFreeRing = true;

  bool _isPrimary = true;

  int _adjacentIndex0 = -1;

  int _adjacentIndex1 = -1;

  CoverageEdge(Array<Coordinate> pts, bool isPrimary, bool isFreeRing) {
    _pts = pts;
    _isPrimary = isPrimary;
    _isFreeRing = isFreeRing;
  }

  void incRingCount() {
    _ringCount++;
  }

  int getRingCount() {
    return _ringCount;
  }

  bool isInner() {
    return _ringCount == RING_COUNT_INNER;
  }

  bool isOuter() {
    return _ringCount == RING_COUNT_OUTER;
  }

  void setPrimary(bool isPrimary) {
    if (_isPrimary) {
      return;
    }

    _isPrimary = isPrimary;
  }

  bool isRemovableRing() {
    bool isRing = CoordinateArrays.isRing(_pts);
    return isRing && (!_isPrimary);
  }

  bool isFreeRing() {
    return _isFreeRing;
  }

  void setCoordinates(Array<Coordinate> pts) {
    _pts = pts;
  }

  Array<Coordinate> getCoordinates() {
    return _pts;
  }

  Coordinate getEndCoordinate() {
    return _pts[_pts.length - 1];
  }

  Coordinate getStartCoordinate() {
    return _pts[0];
  }

  LineString toLineString(GeometryFactory geomFactory) {
    return geomFactory.createLineString2(getCoordinates());
  }

  void addIndex(int index) {
    if (_adjacentIndex0 < 0) {
      _adjacentIndex0 = index;
    } else {
      _adjacentIndex1 = index;
    }
  }

  int getAdjacentIndex(int index) {
    if (index == 0) {
      return _adjacentIndex0;
    }

    return _adjacentIndex1;
  }

  bool hasAdjacentIndex(int index) {
    if (index == 0) {
      return _adjacentIndex0 >= 0;
    }

    return _adjacentIndex1 >= 0;
  }
}
