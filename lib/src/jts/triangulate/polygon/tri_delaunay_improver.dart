import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/triangulate/quadedge/triangle_predicate.dart';
import 'package:dts/src/jts/triangulate/tri/tri.dart';

class TriDelaunayImprover {
  static void improveS(List<Tri> triList) {
    TriDelaunayImprover improver = TriDelaunayImprover(triList);
    improver.improve();
  }

  static final int _kMaxIteration = 200;

  List<Tri> triList;

  TriDelaunayImprover(this.triList);

  void improve() {
    for (int i = 0; i < _kMaxIteration; i++) {
      int improveCount = improveScan(triList);
      if (improveCount == 0) {
        return;
      }
    }
  }

  int improveScan(List<Tri> triList) {
    int improveCount = 0;
    for (int i = 0; i < (triList.length - 1); i++) {
      Tri tri = triList[i];
      for (int j = 0; j < 3; j++) {
        if (improveNonDelaunay(tri, j)) {
          improveCount++;
        }
      }
    }
    return improveCount;
  }

  bool improveNonDelaunay(Tri? tri, int index) {
    if (tri == null) {
      return false;
    }
    Tri? tri1 = tri.getAdjacent(index);
    if (tri1 == null) {
      return false;
    }
    int index1 = tri1.getIndex2(tri);
    Coordinate adj0 = tri.getCoordinate(index);
    Coordinate adj1 = tri.getCoordinate(Tri.next(index));
    Coordinate opp0 = tri.getCoordinate(Tri.oppVertex(index));
    Coordinate opp1 = tri1.getCoordinate(Tri.oppVertex(index1));
    if (!isConvex(adj0, adj1, opp0, opp1)) {
      return false;
    }
    if (!isDelaunay(adj0, adj1, opp0, opp1)) {
      tri.flip(index);
      return true;
    }
    return false;
  }

  static bool isConvex(Coordinate adj0, Coordinate adj1, Coordinate opp0, Coordinate opp1) {
    int dir0 = Orientation.index(opp0, adj0, opp1);
    int dir1 = Orientation.index(opp1, adj1, opp0);
    bool isConvex = dir0 == dir1;
    return isConvex;
  }

  static bool isDelaunay(Coordinate adj0, Coordinate adj1, Coordinate opp0, Coordinate opp1) {
    if (isInCircle(adj0, adj1, opp0, opp1)) return false;

    if (isInCircle(adj1, adj0, opp1, opp0)) return false;

    return true;
  }

  static bool isInCircle(Coordinate a, Coordinate b, Coordinate c, Coordinate p) {
    return TrianglePredicate.isInCircleRobust(a, c, b, p);
  }
}
