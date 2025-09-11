import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/quadrant.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/index/segment_intersector.dart';

import '../../geom/coordinate.dart';

class GMonotoneChain {
  MonotoneChainEdge mce;

  int chainIndex;

  GMonotoneChain(this.mce, this.chainIndex);

  void computeIntersections(GMonotoneChain mc, SegmentIntersector si) {
    mce.computeIntersectsForChain2(chainIndex, mc.mce, mc.chainIndex, si);
  }
}

class MonotoneChainEdge {
  Edge e;

  late List<Coordinate> pts;

  late List<int> startIndex;

  MonotoneChainEdge(this.e) {
    pts = e.getCoordinates();
    final mcb = MonotoneChainIndexer();
    startIndex = mcb.getChainStartIndices(pts);
  }

  List<Coordinate> getCoordinates() => pts;

  List<int> getStartIndexes() => startIndex;

  double getMinX(int chainIndex) {
    double x1 = pts[startIndex[chainIndex]].x;
    double x2 = pts[startIndex[chainIndex + 1]].x;
    return x1 < x2 ? x1 : x2;
  }

  double getMaxX(int chainIndex) {
    double x1 = pts[startIndex[chainIndex]].x;
    double x2 = pts[startIndex[chainIndex + 1]].x;
    return x1 > x2 ? x1 : x2;
  }

  void computeIntersects(MonotoneChainEdge mce, SegmentIntersector si) {
    for (int i = 0; i < (startIndex.length - 1); i++) {
      for (int j = 0; j < (mce.startIndex.length - 1); j++) {
        computeIntersectsForChain2(i, mce, j, si);
      }
    }
  }

  void computeIntersectsForChain2(int chainIndex0, MonotoneChainEdge mce,
      int chainIndex1, SegmentIntersector si) {
    computeIntersectsForChain(
      startIndex[chainIndex0],
      startIndex[chainIndex0 + 1],
      mce,
      mce.startIndex[chainIndex1],
      mce.startIndex[chainIndex1 + 1],
      si,
    );
  }

  void computeIntersectsForChain(
    int start0,
    int end0,
    MonotoneChainEdge mce,
    int start1,
    int end1,
    SegmentIntersector ei,
  ) {
    if (((end0 - start0) == 1) && ((end1 - start1) == 1)) {
      ei.addIntersections(e, start0, mce.e, start1);
      return;
    }
    if (!overlaps(start0, end0, mce, start1, end1)) {
      return;
    }

    int mid0 = (start0 + end0) ~/ 2;
    int mid1 = (start1 + end1) ~/ 2;
    if (start0 < mid0) {
      if (start1 < mid1) {
        computeIntersectsForChain(start0, mid0, mce, start1, mid1, ei);
      }

      if (mid1 < end1) {
        computeIntersectsForChain(start0, mid0, mce, mid1, end1, ei);
      }
    }
    if (mid0 < end0) {
      if (start1 < mid1) {
        computeIntersectsForChain(mid0, end0, mce, start1, mid1, ei);
      }

      if (mid1 < end1) {
        computeIntersectsForChain(mid0, end0, mce, mid1, end1, ei);
      }
    }
  }

  bool overlaps(
      int start0, int end0, MonotoneChainEdge mce, int start1, int end1) {
    return Envelope.intersects4(
        pts[start0], pts[end0], mce.pts[start1], mce.pts[end1]);
  }
}

class MonotoneChainIndexer {
  List<int> getChainStartIndices(List<Coordinate> pts) {
    int start = 0;
    List<int> startIndexList = [];
    startIndexList.add(start);
    do {
      int last = findChainEnd(pts, start);
      startIndexList.add(last);
      start = last;
    } while (start < (pts.length - 1));
    return startIndexList;
  }

  List<int> oldGetChainStartIndices(List<Coordinate> pts) {
    int start = 0;
    List<int> startIndexList = [];
    startIndexList.add(start);
    do {
      int last = findChainEnd(pts, start);
      startIndexList.add(last);
      start = last;
    } while (start < (pts.length - 1));
    return startIndexList;
  }

  int findChainEnd(List<Coordinate> pts, int start) {
    int chainQuad = Quadrant.quadrant2(pts[start], pts[start + 1]);
    int last = start + 1;
    while (last < pts.length) {
      int quad = Quadrant.quadrant2(pts[last - 1], pts[last]);
      if (quad != chainQuad) {
        break;
      }

      last++;
    }
    return last - 1;
  }
}
