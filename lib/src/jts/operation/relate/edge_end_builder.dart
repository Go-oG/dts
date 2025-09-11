import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/label.dart';

class EdgeEndBuilder {
  List<EdgeEnd> computeEdgeEnds2(Iterable<Edge> edges) {
    List<EdgeEnd> l = [];
    for (var e in edges) {
      computeEdgeEnds(e, l);
    }
    return l;
  }

  void computeEdgeEnds(Edge edge, List<EdgeEnd> l) {
    final eiList = edge.getEdgeIntersectionList();
    eiList.addEndpoints();

    final it = eiList.iterator().iterator;

    EdgeIntersection? eiPrev;
    EdgeIntersection? eiCurr;
    if (!it.moveNext()) return;
    EdgeIntersection? eiNext = it.current;

    do {
      eiPrev = eiCurr;
      eiCurr = eiNext;
      eiNext = null;
      if (it.moveNext()) {
        eiNext = it.current;
      }

      if (eiCurr != null) {
        createEdgeEndForPrev(edge, l, eiCurr, eiPrev);
        createEdgeEndForNext(edge, l, eiCurr, eiNext);
      }
    } while (eiCurr != null);
  }

  void createEdgeEndForPrev(Edge edge, List<EdgeEnd> l, EdgeIntersection eiCurr,
      EdgeIntersection? eiPrev) {
    int iPrev = eiCurr.segmentIndex;
    if (eiCurr.dist == 0.0) {
      if (iPrev == 0) return;

      iPrev--;
    }
    Coordinate pPrev = edge.getCoordinate2(iPrev);
    if ((eiPrev != null) && (eiPrev.segmentIndex >= iPrev)) {
      pPrev = eiPrev.coord;
    }

    Label label = Label(edge.getLabel()!);
    label.flip();
    EdgeEnd e = EdgeEnd.of2(edge, eiCurr.coord, pPrev, label);
    l.add(e);
  }

  void createEdgeEndForNext(Edge edge, List<EdgeEnd> l, EdgeIntersection eiCurr,
      EdgeIntersection? eiNext) {
    int iNext = eiCurr.segmentIndex + 1;
    if ((iNext >= edge.getNumPoints()) && (eiNext == null)) return;

    Coordinate pNext = edge.getCoordinate2(iNext);
    if ((eiNext != null) && (eiNext.segmentIndex == eiCurr.segmentIndex)) {
      pNext = eiNext.coord;
    }

    EdgeEnd e = EdgeEnd.of2(edge, eiCurr.coord, pNext, Label(edge.getLabel()!));
    l.add(e);
  }
}
