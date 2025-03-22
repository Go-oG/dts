 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';

class LinkedLine {
  static const int _NO_COORD_INDEX = -1;

  late final Array<Coordinate> _coord;

  late bool isRing;

  late int _size;

  late Array<int> _next;

  late Array<int> _prev;

  LinkedLine(Array<Coordinate> pts) {
    _coord = pts;
    isRing = CoordinateArrays.isRing(pts);
    _size = (isRing) ? pts.length - 1 : pts.length;
    _next = createNextLinks(_size);
    _prev = createPrevLinks(_size);
  }

  bool isCorner(int i) {
    if ((!isRing) && ((i == 0) || (i == (_coord.length - 1)))) return false;

    return true;
  }

  Array<int> createNextLinks(int size) {
    Array<int> next = Array(size);
    for (int i = 0; i < size; i++) {
      next[i] = i + 1;
    }
    next[size - 1] = (isRing) ? 0 : _NO_COORD_INDEX;
    return next;
  }

  Array<int> createPrevLinks(int size) {
    Array<int> prev = Array(size);
    for (int i = 0; i < size; i++) {
      prev[i] = i - 1;
    }
    prev[0] = (isRing) ? size - 1 : _NO_COORD_INDEX;
    return prev;
  }

  int size() {
    return _size;
  }

  int next(int i) {
    return _next[i];
  }

  int prev(int i) {
    return _prev[i];
  }

  Coordinate getCoordinate(int index) {
    return _coord[index];
  }

  Coordinate prevCoordinate(int index) {
    return _coord[prev(index)];
  }

  Coordinate nextCoordinate(int index) {
    return _coord[next(index)];
  }

  bool hasCoordinate(int index) {
    if ((!isRing) && ((index == 0) || (index == (_coord.length - 1)))) {
      return true;
    }

    return ((index >= 0) && (index < _prev.length)) && (_prev[index] != _NO_COORD_INDEX);
  }

  void remove(int index) {
    int iprev = _prev[index];
    int inext = _next[index];
    if (iprev != _NO_COORD_INDEX) {
      _next[iprev] = inext;
    }

    if (inext != _NO_COORD_INDEX) {
      _prev[inext] = iprev;
    }

    _prev[index] = _NO_COORD_INDEX;
    _next[index] = _NO_COORD_INDEX;
    _size--;
  }

  Array<Coordinate> getCoordinates() {
    CoordinateList coords = CoordinateList();
    int len = (isRing) ? _coord.length - 1 : _coord.length;
    for (int i = 0; i < len; i++) {
      if (hasCoordinate(i)) {
        coords.add3(_coord[i].copy(), false);
      }
    }
    if (isRing) {
      coords.closeRing();
    }
    return coords.toCoordinateArray();
  }
}
