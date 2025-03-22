import '../geom/coordinate.dart';
import 'directed_edge.dart';
import 'edge.dart';

class DirectedEdgeStarPG {
  List<DirectedEdgePG> outEdges = [];

  bool _sorted = false;

  void add(DirectedEdgePG de) {
    outEdges.add(de);
    _sorted = false;
  }

  void remove(DirectedEdgePG de) {
    outEdges.remove(de);
  }

  List<DirectedEdgePG> iterator() {
    sortEdges();
    return outEdges;
  }

  int getDegree() {
    return outEdges.length;
  }

  Coordinate? getCoordinate() {
    final it = iterator();
    return it.firstOrNull?.getCoordinate();
  }

  List<DirectedEdgePG> getEdges() {
    sortEdges();
    return outEdges;
  }

  void sortEdges() {
    if (!_sorted) {
      outEdges.sort();
      _sorted = true;
    }
  }

  int getIndex2(PGEdge edge) {
    sortEdges();
    for (int i = 0; i < outEdges.length; i++) {
      DirectedEdgePG de = outEdges[i];
      if (de.getEdge() == edge) return i;
    }
    return -1;
  }

  int getIndex3(DirectedEdgePG dirEdge) {
    sortEdges();
    for (int i = 0; i < outEdges.length; i++) {
      DirectedEdgePG de = outEdges[i];
      if (de == dirEdge) return i;
    }
    return -1;
  }

  int getIndex(int i) {
    int modi = i % outEdges.length;
    if (modi < 0) modi += outEdges.length;

    return modi;
  }

  DirectedEdgePG getNextEdge(DirectedEdgePG dirEdge) {
    int i = getIndex3(dirEdge);
    return outEdges[getIndex(i + 1)];
  }

  DirectedEdgePG getNextCWEdge(DirectedEdgePG dirEdge) {
    int i = getIndex3(dirEdge);
    return outEdges[getIndex(i - 1)];
  }
}
