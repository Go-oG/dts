import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';

class LinkedRing {
  static const int kNoCoordIndex = -1;

  static List<int> createNextLinks(int size) {
    List<int> next = List.filled(size, 0);
    for (int i = 0; i < size; i++) {
      next[i] = i + 1;
    }
    next[size - 1] = 0;
    return next;
  }

  static List<int> createPrevLinks(int size) {
    List<int> prev = List.filled(size, 0);
    for (int i = 0; i < size; i++) {
      prev[i] = i - 1;
    }
    prev[0] = size - 1;
    return prev;
  }

  final List<Coordinate> coord;

  late List<int> next;

  late List<int> prev;

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
    return ((index >= 0) && (index < prev.length)) &&
        (prev[index] != kNoCoordIndex);
  }

  void remove(int index) {
    int iprev = prev[index];
    int inext = next[index];
    next[iprev] = inext;
    prev[inext] = iprev;
    prev[index] = kNoCoordIndex;
    next[index] = kNoCoordIndex;
    size--;
  }

  List<Coordinate> getCoordinates() {
    CoordinateList coords = CoordinateList();
    for (int i = 0; i < (coord.length - 1); i++) {
      if (prev[i] != kNoCoordIndex) {
        coords.add3(coord[i].copy(), false);
      }
    }
    coords.closeRing();
    return coords.toCoordinateList();
  }
}
