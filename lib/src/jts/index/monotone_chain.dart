 import 'package:d_util/d_util.dart';

import '../geom/coordinate.dart';
import '../geom/envelope.dart';
import '../geom/line_segment.dart';
import '../geom/quadrant.dart';

class MonotoneChain<T> {
  Array<Coordinate> pts;
  final int _start;
  final int _end;
  final T? context;

  Envelope? _env;
  int id = 0;

  MonotoneChain(this.pts, this._start, this._end, this.context);

  void setOverlapDistance(double distance) {}

  E getContext<E>() {
    return context as E;
  }

  Envelope getEnvelope([double expansionDistance = 0.0]) {
    if (_env == null) {
      Coordinate p0 = pts[_start];
      Coordinate p1 = pts[_end];
      _env = Envelope.of3(p0, p1);
      if (expansionDistance > 0.0) {
        _env!.expandBy(expansionDistance);
      }
    }
    return _env!;
  }

  int getStartIndex() {
    return _start;
  }

  int getEndIndex() {
    return _end;
  }

  void getLineSegment(int index, LineSegment ls) {
    ls.p0 = pts[index];
    ls.p1 = pts[index + 1];
  }

  Array<Coordinate> getCoordinates() {
    List<Coordinate> list = [];
    for (int i = _start; i <= _end; i++) {
      list.add(pts[i]);
    }
    return list.toArray();
  }

  void select(Envelope searchEnv, MonotoneChainSelectAction mcs) {
    computeSelect(searchEnv, _start, _end, mcs);
  }

  void computeSelect(Envelope searchEnv, int start0, int end0, MonotoneChainSelectAction mcs) {
    Coordinate p0 = pts[start0];
    Coordinate p1 = pts[end0];
    if ((end0 - start0) == 1) {
      mcs.select2(this, start0);
      return;
    }
    if (!searchEnv.intersects2(p0, p1)) {
      return;
    }

    int mid = (start0 + end0) ~/ 2;
    if (start0 < mid) {
      computeSelect(searchEnv, start0, mid, mcs);
    }
    if (mid < end0) {
      computeSelect(searchEnv, mid, end0, mcs);
    }
  }

  void computeOverlaps(MonotoneChain mc, MonotoneChainOverlapAction mco) {
    computeOverlaps2(_start, _end, mc, mc._start, mc._end, 0.0, mco);
  }

  void computeOverlaps3(MonotoneChain mc, double overlapTolerance, MonotoneChainOverlapAction mco) {
    computeOverlaps2(_start, _end, mc, mc._start, mc._end, overlapTolerance, mco);
  }

  void computeOverlaps2(
    int start0,
    int end0,
    MonotoneChain mc,
    int start1,
    int end1,
    double overlapTolerance,
    MonotoneChainOverlapAction mco,
  ) {
    if (((end0 - start0) == 1) && ((end1 - start1) == 1)) {
      mco.overlap2(this, start0, mc, start1);
      return;
    }
    if (!overlaps2(start0, end0, mc, start1, end1, overlapTolerance)) {
      return;
    }

    int mid0 = (start0 + end0) ~/ 2;
    int mid1 = (start1 + end1) ~/ 2;
    if (start0 < mid0) {
      if (start1 < mid1) {
        computeOverlaps2(start0, mid0, mc, start1, mid1, overlapTolerance, mco);
      }

      if (mid1 < end1) {
        computeOverlaps2(start0, mid0, mc, mid1, end1, overlapTolerance, mco);
      }
    }
    if (mid0 < end0) {
      if (start1 < mid1) {
        computeOverlaps2(mid0, end0, mc, start1, mid1, overlapTolerance, mco);
      }

      if (mid1 < end1) {
        computeOverlaps2(mid0, end0, mc, mid1, end1, overlapTolerance, mco);
      }
    }
  }

  bool overlaps(Coordinate p1, Coordinate p2, Coordinate q1, Coordinate q2, double overlapTolerance) {
    double minq = Math.minD(q1.x, q2.x);
    double maxq = Math.maxD(q1.x, q2.x);
    double minp = Math.minD(p1.x, p2.x);
    double maxp = Math.maxD(p1.x, p2.x);
    if (minp > (maxq + overlapTolerance)) {
      return false;
    }

    if (maxp < (minq - overlapTolerance)) {
      return false;
    }

    minq = Math.minD(q1.y, q2.y);
    maxq = Math.maxD(q1.y, q2.y);
    minp = Math.minD(p1.y, p2.y);
    maxp = Math.maxD(p1.y, p2.y);
    if (minp > (maxq + overlapTolerance)) {
      return false;
    }

    if (maxp < (minq - overlapTolerance)) {
      return false;
    }

    return true;
  }

  bool overlaps2(int start0, int end0, MonotoneChain mc, int start1, int end1, double overlapTolerance) {
    if (overlapTolerance > 0.0) {
      return overlaps(pts[start0], pts[end0], mc.pts[start1], mc.pts[end1], overlapTolerance);
    }
    return Envelope.intersects4(pts[start0], pts[end0], mc.pts[start1], mc.pts[end1]);
  }
}

class MonotoneChainBuilder {
  MonotoneChainBuilder._();

  static List<MonotoneChain> getChains<T>(Array<Coordinate> pts, [T? context]) {
    List<MonotoneChain> mcList = [];
    if (pts.isEmpty) {
      return mcList;
    }
    int chainStart = 0;
    do {
      int chainEnd = findChainEnd(pts, chainStart);
      MonotoneChain mc = MonotoneChain(pts, chainStart, chainEnd, context);
      mcList.add(mc);
      chainStart = chainEnd;
    } while (chainStart < (pts.length - 1));
    return mcList;
  }

  static int findChainEnd(Array<Coordinate> pts, int start) {
    int safeStart = start;
    while ((safeStart < (pts.length - 1)) && pts[safeStart].equals2D(pts[safeStart + 1])) {
      safeStart++;
    }
    if (safeStart >= (pts.length - 1)) {
      return pts.length - 1;
    }
    int chainQuad = Quadrant.quadrant2(pts[safeStart], pts[safeStart + 1]);
    int last = start + 1;
    while (last < pts.length) {
      if (!pts[last - 1].equals2D(pts[last])) {
        int quad = Quadrant.quadrant2(pts[last - 1], pts[last]);
        if (quad != chainQuad) {
          break;
        }
      }
      last++;
    }
    return last - 1;
  }
}

class MonotoneChainOverlapAction {
  LineSegment overlapSeg1 = LineSegment.empty();
  LineSegment overlapSeg2 = LineSegment.empty();

  void overlap2(MonotoneChain mc1, int start1, MonotoneChain mc2, int start2) {
    mc1.getLineSegment(start1, overlapSeg1);
    mc2.getLineSegment(start2, overlapSeg2);
    overlap(overlapSeg1, overlapSeg2);
  }

  void overlap(LineSegment seg1, LineSegment seg2) {}
}

class MonotoneChainSelectAction {
  LineSegment selectedSegment = LineSegment.empty();

  void select2(MonotoneChain mc, int startIndex) {
    mc.getLineSegment(startIndex, selectedSegment);
    select(selectedSegment);
  }

  void select(LineSegment seg) {}
}
