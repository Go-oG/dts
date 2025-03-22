 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/noding/basic_segment_string.dart';

import '../geom/geometry_filter.dart';

class CoverageRing extends BasicSegmentString {
  static List<CoverageRing> createRings(Geometry geom) {
    List<Polygon> polygons = PolygonExtracter.getPolygons(geom);
    return createRings2(polygons);
  }

  static List<CoverageRing> createRings2(List<Polygon> polygons) {
    List<CoverageRing> rings = [];
    for (Polygon poly in polygons) {
      _createRings(poly, rings);
    }
    return rings;
  }

  static void _createRings(Polygon poly, List<CoverageRing> rings) {
    if (poly.isEmpty()) {
      return;
    }

    _addRing(poly.getExteriorRing(), true, rings);
    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      _addRing(poly.getInteriorRingN(i), false, rings);
    }
  }

  static void _addRing(LinearRing ring, bool isShell, List<CoverageRing> rings) {
    if (ring.isEmpty()) {
      return;
    }

    rings.add(_createRing(ring, isShell));
  }

  static CoverageRing _createRing(LinearRing ring, bool isShell) {
    Array<Coordinate> pts = ring.getCoordinates();
    if (CoordinateArrays.hasRepeatedOrInvalidPoints(pts)) {
      pts = CoordinateArrays.removeRepeatedOrInvalidPoints(pts);
    }
    bool isCCW = Orientation.isCCW(pts);
    bool isInteriorOnRight = (isShell) ? !isCCW : isCCW;
    return CoverageRing(pts, isInteriorOnRight);
  }

  static bool isKnownS(List<CoverageRing> rings) {
    for (CoverageRing ring in rings) {
      if (!ring.isKnown()) {
        return false;
      }
    }
    return true;
  }

  final bool _isInteriorOnRight;

  late Array<bool> _isInvalid;

  late Array<bool> _isMatched;

  CoverageRing(Array<Coordinate> pts, this._isInteriorOnRight) : super(pts, null) {
    _isInvalid = Array(size() - 1);
    _isMatched = Array(size() - 1);
  }

  Envelope getEnvelope(int start, int end) {
    Envelope env = Envelope();
    for (int i = start; i < end; i++) {
      env.expandToInclude(getCoordinate(i));
    }
    return env;
  }

  bool isInteriorOnRight() {
    return _isInteriorOnRight;
  }

  void markInvalid(int i) {
    _isInvalid[i] = true;
  }

  void markMatched(int i) {
    _isMatched[i] = true;
  }

  bool isKnown() {
    for (int i = 0; i < _isMatched.length; i++) {
      if (!(_isMatched[i] && _isInvalid[i])) {
        return false;
      }
    }
    return true;
  }

  bool isInvalid2(int index) {
    return _isInvalid[index];
  }

  bool isInvalid() {
    for (int i = 0; i < _isInvalid.length; i++) {
      if (!_isInvalid[i]) {
        return false;
      }
    }
    return true;
  }

  bool hasInvalid() {
    for (int i = 0; i < _isInvalid.length; i++) {
      if (_isInvalid[i]) {
        return true;
      }
    }
    return false;
  }

  bool isKnown2(int i) {
    return _isMatched[i] || _isInvalid[i];
  }

  Coordinate findVertexPrev(int index, Coordinate pt) {
    int iPrev = index;
    Coordinate prevV = getCoordinate(iPrev);
    while (pt.equals2D(prevV)) {
      iPrev = prev(iPrev);
      prevV = getCoordinate(iPrev);
    }
    return prevV;
  }

  Coordinate findVertexNext(int index, Coordinate pt) {
    int iNext = index + 1;
    Coordinate nextV = getCoordinate(iNext);
    while (pt.equals2D(nextV)) {
      iNext = next(iNext);
      nextV = getCoordinate(iNext);
    }
    return nextV;
  }

  int prev(int index) {
    if (index == 0) {
      return size() - 2;
    }

    return index - 1;
  }

  int next(int index) {
    if (index < (size() - 2)) {
      return index + 1;
    }

    return 0;
  }

  void createInvalidLines(GeometryFactory geomFactory, List<LineString> lines) {
    if (!hasInvalid()) {
      return;
    }
    if (isInvalid()) {
      LineString line = _createLine(0, size() - 1, geomFactory);
      lines.add(line);
      return;
    }
    int startIndex = _findInvalidStart(0);
    int firstEndIndex = _findInvalidEnd(startIndex);
    int endIndex = firstEndIndex;
    while (true) {
      startIndex = _findInvalidStart(endIndex);
      endIndex = _findInvalidEnd(startIndex);
      LineString line = _createLine(startIndex, endIndex, geomFactory);
      lines.add(line);
      if (endIndex == firstEndIndex) {
        break;
      }
    }
  }

  int _findInvalidStart(int index) {
    while (!isInvalid2(index)) {
      index = _nextMarkIndex(index);
    }
    return index;
  }

  int _findInvalidEnd(int index) {
    index = _nextMarkIndex(index);
    while (isInvalid2(index)) {
      index = _nextMarkIndex(index);
    }
    return index;
  }

  int _nextMarkIndex(int index) {
    if (index >= (_isInvalid.length - 1)) {
      return 0;
    }
    return index + 1;
  }

  LineString _createLine(int startIndex, int endIndex, GeometryFactory geomFactory) {
    Array<Coordinate> pts =
        (endIndex < startIndex) ? _extractSectionWrap(startIndex, endIndex) : _extractSection(startIndex, endIndex);
    return geomFactory.createLineString2(pts);
  }

  Array<Coordinate> _extractSection(int startIndex, int endIndex) {
    int size = (endIndex - startIndex) + 1;
    Array<Coordinate> pts = Array<Coordinate>(size);
    int ipts = 0;
    for (int i = startIndex; i <= endIndex; i++) {
      pts[ipts++] = getCoordinate(i).copy();
    }
    return pts;
  }

  Array<Coordinate> _extractSectionWrap(int startIndex, int endIndex) {
    int sizeV = (endIndex + (size() - startIndex));
    Array<Coordinate> pts = Array<Coordinate>(sizeV);
    int index = startIndex;
    for (int i = 0; i < sizeV; i++) {
      pts[i] = getCoordinate(index).copy();
      index = _nextMarkIndex(index);
    }
    return pts;
  }
}
