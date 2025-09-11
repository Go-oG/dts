import 'dart:collection';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/triangle.dart';
import 'package:dts/src/jts/triangulate/tri/tri.dart';

class HullTri extends Tri implements Comparable<HullTri> {
  late double _size;

  bool _isMarked = false;

  HullTri(super.p0, super.p1, super.p2) {
    _size = lengthOfLongestEdge();
  }

  double getSize() {
    return _size;
  }

  void setSizeToBoundary() {
    _size = lengthOfBoundary();
  }

  void setSizeToLongestEdge() {
    _size = lengthOfLongestEdge();
  }

  void setSizeToCircumradius() {
    _size = Triangle.circumradius2(p2, p1, p0);
  }

  bool isMarked() {
    return _isMarked;
  }

  void setMarked(bool isMarked) {
    _isMarked = isMarked;
  }

  bool isRemoved() {
    return !hasAdjacent();
  }

  int boundaryIndex() {
    if (isBoundary(0)) {
      return 0;
    }

    if (isBoundary(1)) {
      return 1;
    }

    if (isBoundary(2)) {
      return 2;
    }

    return -1;
  }

  int boundaryIndexCCW() {
    int index = boundaryIndex();
    if (index < 0) {
      return -1;
    }

    int prevIndex = Tri.prev(index);
    if (isBoundary(prevIndex)) {
      return prevIndex;
    }
    return index;
  }

  int boundaryIndexCW() {
    int index = boundaryIndex();
    if (index < 0) {
      return -1;
    }

    int nextIndex = Tri.next(index);
    if (isBoundary(nextIndex)) {
      return nextIndex;
    }
    return index;
  }

  bool isConnecting() {
    int adj2Index = adjacent2VertexIndex();
    bool isInterior = isInteriorVertex(adj2Index);
    return !isInterior;
  }

  int adjacent2VertexIndex() {
    if (hasAdjacent2(0) && hasAdjacent2(1)) {
      return 1;
    }

    if (hasAdjacent2(1) && hasAdjacent2(2)) {
      return 2;
    }

    if (hasAdjacent2(2) && hasAdjacent2(0)) {
      return 0;
    }

    return -1;
  }

  int isolatedVertexIndex(List<HullTri> triList) {
    for (int i = 0; i < 3; i++) {
      if (degree(i, triList) <= 1) {
        return i;
      }
    }
    return -1;
  }

  double lengthOfLongestEdge() {
    return Triangle.longestSideLength2(p0, p1, p2);
  }

  double lengthOfBoundary() {
    double len = 0.0;
    for (int i = 0; i < 3; i++) {
      if (!hasAdjacent2(i)) {
        len += getCoordinate(i).distance(getCoordinate(Tri.next(i)));
      }
    }
    return len;
  }

  @override
  int compareTo(HullTri o) {
    if (_size == o._size) {
      return -Double.compare(getArea(), o.getArea());
    }
    return -Double.compare(_size, o._size);
  }

  bool hasBoundaryTouch() {
    for (int i = 0; i < 3; i++) {
      if (_isBoundaryTouch(i)) {
        return true;
      }
    }
    return false;
  }

  bool _isBoundaryTouch(int index) {
    if (isBoundary(index)) {
      return false;
    }

    if (isBoundary(Tri.prev(index))) {
      return false;
    }

    return !isInteriorVertex(index);
  }

  static HullTri? findTri(List<HullTri> triList, Tri exceptTri) {
    for (HullTri tri in triList) {
      if (tri != exceptTri) {
        return tri;
      }
    }
    return null;
  }

  static bool isAllMarked(List<HullTri> triList) {
    for (HullTri tri in triList) {
      if (!tri.isMarked()) {
        return false;
      }
    }
    return true;
  }

  static void clearMarks(List<HullTri> triList) {
    for (HullTri tri in triList) {
      tri.setMarked(false);
    }
  }

  static void markConnected(HullTri triStart, Tri exceptTri) {
    Queue<HullTri> queue = Queue<HullTri>();
    queue.add(triStart);
    while (queue.isNotEmpty) {
      HullTri tri = queue.removeFirst();
      tri.setMarked(true);
      for (int i = 0; i < 3; i++) {
        HullTri? adj = ((tri.getAdjacent(i) as HullTri?));
        if (adj == exceptTri) {
          continue;
        }
        if ((adj != null) && (!adj.isMarked())) {
          queue.add(adj);
        }
      }
    }
  }

  static bool isConnected(List<HullTri> triList, HullTri removedTri) {
    if (triList.size == 0) {
      return false;
    }

    clearMarks(triList);
    HullTri triStart = findTri(triList, removedTri)!;
    markConnected(triStart, removedTri);
    removedTri.setMarked(true);
    return isAllMarked(triList);
  }
}
