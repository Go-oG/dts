 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';

class LinkedRing {
  static const int NO_COORD_INDEX = -1;

  static Array<int> createNextLinks(int size) {
    Array<int> next = Array(size);
    for (int i = 0; i < size; i++) {
      next[i] = i + 1;
    }
    next[size - 1] = 0;
    return next;
  }

  static Array<int> createPrevLinks(int size) {
    Array<int> prev = Array(size);
    for (int i = 0; i < size; i++) {
      prev[i] = i - 1;
    }
    prev[0] = size - 1;
    return prev;
  }

  final Array<Coordinate> coord;

  late Array<int> next;

  late Array<int> prev;

  late int size;

  LinkedRing(this.coord) {
    size = coord.length - 1;
    next = createNextLinks(size);
    prev = createPrevLinks(size);
  }

  int getNext(int i) {
    return next[i];
  }

  int getPrev(int i) {
    return prev[i];
  }

  Coordinate getCoordinate(int index) {
    return coord[index];
  }

  Coordinate prevCoordinate(int index) {
    return coord[getPrev(index)];
  }

  Coordinate nextCoordinate(int index) {
    return coord[getNext(index)];
  }

  bool hasCoordinate(int index) {
    return ((index >= 0) && (index < prev.length)) && (prev[index] != NO_COORD_INDEX);
  }

  void remove(int index) {
    int iprev = prev[index];
    int inext = next[index];
    next[iprev] = inext;
    prev[inext] = iprev;
    prev[index] = NO_COORD_INDEX;
    next[index] = NO_COORD_INDEX;
    size--;
  }

  Array<Coordinate> getCoordinates() {
    CoordinateList coords = CoordinateList();
    for (int i = 0; i < (coord.length - 1); i++) {
      if (prev[i] != NO_COORD_INDEX) {
        coords.add3(coord[i].copy(), false);
      }
    }
    coords.closeRing();
    return coords.toCoordinateArray();
  }
}
