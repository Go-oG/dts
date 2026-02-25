import 'dart:collection';

import 'package:dts/src/jts/geom/coordinate.dart';

import 'node.dart';

class PGNodeMap {
  final Map<Coordinate, PGNode> nodeMap = SplayTreeMap();

  PGNode add(PGNode n) {
    nodeMap[n.getCoordinate()!] = n;
    return n;
  }

  PGNode? remove(Coordinate? pt) {
    return nodeMap.remove(pt);
  }

  PGNode? find(Coordinate coord) {
    return nodeMap[coord];
  }

  Iterable<PGNode> iterator() {
    return nodeMap.values;
  }

  List<PGNode> values() {
    return nodeMap.values.toList();
  }
}
