import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';

class CoverageEdge {
  static const int kRingCountInner = 2;
  static const int kRingCountOuter = 1;

  static CoverageEdge createEdge(List<Coordinate> ring, bool isPrimary) {
    final pts = _extractEdgePoints(ring, 0, ring.length - 1);
    CoverageEdge edge = CoverageEdge(pts, isPrimary, true);
    return edge;
  }

  static CoverageEdge createEdge2(List<Coordinate> ring, int start, int end, bool isPrimary) {
    final pts = _extractEdgePoints(ring, start, end);
    CoverageEdge edge = CoverageEdge(pts, isPrimary, false);
    return edge;
  }

  static List<Coordinate> _extractEdgePoints(List<Coordinate> ring, int start, int end) {
    int size = (start < end) ? (end - start) + 1 : (ring.length - start) + end;
    List<Coordinate> pts = [];
    int iring = start;
    for (int i = 0; i < size; i++) {
      pts.add(ring[iring].copy());
      iring += 1;
      if (iring >= ring.length) {
        iring = 1;
      }
    }
    return pts;
  }

  static LineSegment key(List<Coordinate> ring) {
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

  static LineSegment key2(List<Coordinate> ring, int start, int end) {
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

  static Coordinate _findDistinctPoint(List<Coordinate> pts, int index, bool isForward, Coordinate pt) {
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

  late List<Coordinate> _pts;

  int _ringCount = 0;

  final bool _isFreeRing;

  bool _isPrimary = true;

  int _adjacentIndex0 = -1;

  int _adjacentIndex1 = -1;

  CoverageEdge(this._pts, this._isPrimary, this._isFreeRing);

  void incRingCount() {
    _ringCount++;
  }

  int getRingCount() {
    return _ringCount;
  }

  bool isInner() {
    return _ringCount == kRingCountInner;
  }

  bool isOuter() {
    return _ringCount == kRingCountOuter;
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

  void setCoordinates(List<Coordinate> pts) => _pts = pts;

  List<Coordinate> getCoordinates() => _pts;

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
