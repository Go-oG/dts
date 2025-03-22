 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

import 'basic_segment_string.dart';
import 'noder.dart';
import 'segment_string.dart';

class NBoundaryChainNoder implements Noder {
  List<SegmentString>? _chainList;

  @override
  void computeNodes(List<SegmentString> segStrings) {
    Set<_Segment> segSet = <_Segment>{};
    Array<_BoundaryChainMap> boundaryChains = Array(segStrings.length);

    addSegments(segStrings, segSet, boundaryChains);
    markBoundarySegments(segSet);
    _chainList = extractChains(boundaryChains);
  }

  static void addSegments(
    List<SegmentString> segStrings,
    Set<_Segment> segSet,
    Array<_BoundaryChainMap> boundaryChains,
  ) {
    int i = 0;
    for (SegmentString ss in segStrings) {
      _BoundaryChainMap chainMap = _BoundaryChainMap(ss);
      boundaryChains[i++] = chainMap;
      addSegments2(ss, chainMap, segSet);
    }
  }

  static void addSegments2(SegmentString segString, _BoundaryChainMap chainMap, Set<_Segment> segSet) {
    for (int i = 0; i < (segString.size() - 1); i++) {
      Coordinate p0 = segString.getCoordinate(i);
      Coordinate p1 = segString.getCoordinate(i + 1);
      _Segment seg = _Segment(p0, p1, chainMap, i);
      if (segSet.contains(seg)) {
        segSet.remove(seg);
      } else {
        segSet.add(seg);
      }
    }
  }

  static void markBoundarySegments(Set<_Segment> segSet) {
    for (_Segment seg in segSet) {
      seg.markBoundary();
    }
  }

  static List<SegmentString> extractChains(Array<_BoundaryChainMap> boundaryChains) {
    List<SegmentString> chainList = [];
    boundaryChains.each((chainMap, index) {
      chainMap.createChains(chainList);
    });
    return chainList;
  }

  @override
  List<SegmentString>? getNodedSubstrings() {
    return _chainList;
  }
}

class _BoundaryChainMap {
  final SegmentString _segString;

  late Array<bool> _isBoundary;

  _BoundaryChainMap(this._segString) {
    _isBoundary = Array(_segString.size() - 1);
  }

  void setBoundarySegment(int index) {
    _isBoundary[index] = true;
  }

  void createChains(List<SegmentString> chainList) {
    int endIndex = 0;
    while (true) {
      int startIndex = findChainStart(endIndex);
      if (startIndex >= (_segString.size() - 1)) break;

      endIndex = findChainEnd(startIndex);
      SegmentString ss = createChain(_segString, startIndex, endIndex);
      chainList.add(ss);
    }
  }

  static SegmentString createChain(SegmentString segString, int startIndex, int endIndex) {
    Array<Coordinate> pts = Array((endIndex - startIndex) + 1);
    int ipts = 0;
    for (int i = startIndex; i < (endIndex + 1); i++) {
      pts[ipts++] = segString.getCoordinate(i).copy();
    }
    return BasicSegmentString(pts, segString.getData());
  }

  int findChainStart(int index) {
    while ((index < _isBoundary.length) && (!_isBoundary[index])) {
      index++;
    }
    return index;
  }

  int findChainEnd(int index) {
    index++;
    while ((index < _isBoundary.length) && _isBoundary[index]) {
      index++;
    }
    return index;
  }
}

class _Segment extends LineSegment {
  final _BoundaryChainMap _segMap;

  int index;

  _Segment(super.p0, super.p1, this._segMap, this.index) {
    normalize();
  }

  void markBoundary() {
    _segMap.setBoundarySegment(index);
  }
}
