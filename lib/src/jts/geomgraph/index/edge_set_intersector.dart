import 'dart:math';

import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/index/segment_intersector.dart';

import 'monotone_chain.dart';
import 'sweep_line_segment.dart';

abstract class EdgeSetIntersector {
  void computeIntersections(List<Edge> edges, SegmentIntersector si, bool testAllSegments);

  void computeIntersections2(List<Edge> edges0, List<Edge> edges1, SegmentIntersector si);
}

class SimpleEdgeSetIntersector extends EdgeSetIntersector {
  int nOverlaps = 0;

  @override
  void computeIntersections(List<Edge> edges, SegmentIntersector si, bool testAllSegments) {
    nOverlaps = 0;
    for (var edge0 in edges) {
      for (var edge1 in edges) {
        if (testAllSegments || (edge0 != edge1)) {
          computeIntersects(edge0, edge1, si);
        }
      }
    }
  }

  @override
  void computeIntersections2(List<Edge> edges0, List<Edge> edges1, SegmentIntersector si) {
    nOverlaps = 0;
    for (var edge0 in edges0) {
      for (var edge1 in edges1) {
        computeIntersects(edge0, edge1, si);
      }
    }
  }

  void computeIntersects(Edge e0, Edge e1, SegmentIntersector si) {
    final pts0 = e0.getCoordinates();
    final pts1 = e1.getCoordinates();
    for (int i0 = 0; i0 < (pts0.length - 1); i0++) {
      for (int i1 = 0; i1 < (pts1.length - 1); i1++) {
        si.addIntersections(e0, i0, e1, i1);
      }
    }
  }
}

class SimpleMCSweepLineIntersector extends EdgeSetIntersector {
  List events = [];

  int nOverlaps = 0;

  SimpleMCSweepLineIntersector();

  @override
  void computeIntersections(List<Edge> edges, SegmentIntersector si, bool testAllSegments) {
    if (testAllSegments) {
      _addEdges(edges, null);
    } else {
      _addEdges3(edges);
    }

    computeIntersections3(si);
  }

  @override
  void computeIntersections2(List<Edge> edges0, List<Edge> edges1, SegmentIntersector si) {
    _addEdges(edges0, edges0);
    _addEdges(edges1, edges1);
    computeIntersections3(si);
  }

  void _addEdges3(List<Edge> edges) {
    for (var edge in edges) {
      _addEdge2(edge, edge);
    }
  }

  void _addEdges(List<Edge> edges, Object? edgeSet) {
    for (var edge in edges) {
      _addEdge2(edge, edgeSet);
    }
  }

  void _addEdge2(Edge edge, Object? edgeSet) {
    MonotoneChainEdge mce = edge.getMonotoneChainEdge();
    final startIndex = mce.getStartIndexes();
    for (int i = 0; i < (startIndex.length - 1); i++) {
      final mc = GMonotoneChain(mce, i);
      final insertEvent = SweepLineEventG(edgeSet, mce.getMinX(i), mc);
      events.add(insertEvent);
      events.add(SweepLineEventG.of(mce.getMaxX(i), insertEvent));
    }
  }

  void prepareEvents() {
    events.sort();
    for (int i = 0; i < events.length; i++) {
      SweepLineEventG ev = events[i];
      if (ev.isDelete()) {
        ev.getInsertEvent()!.setDeleteEventIndex(i);
      }
    }
  }

  void computeIntersections3(SegmentIntersector si) {
    nOverlaps = 0;
    prepareEvents();
    for (int i = 0; i < events.length; i++) {
      SweepLineEventG ev = events[i];
      if (ev.isInsert()) {
        processOverlaps(i, ev.getDeleteEventIndex(), ev, si);
      }
      if (si.isDone()) {
        break;
      }
    }
  }

  void processOverlaps(int start, int end, SweepLineEventG ev0, SegmentIntersector si) {
    GMonotoneChain mc0 = ev0.getObject() as GMonotoneChain;
    for (int i = start; i < end; i++) {
      final ev1 = events[i] as SweepLineEventG;
      if (ev1.isInsert()) {
        final mc1 = ev1.getObject() as GMonotoneChain;
        if (!ev0.isSameLabel(ev1)) {
          mc0.computeIntersections(mc1, si);
          nOverlaps++;
        }
      }
    }
  }
}

class SimpleSweepLineIntersector extends EdgeSetIntersector {
  List<SweepLineEventG> events = [];
  int nOverlaps = 0;

  @override
  void computeIntersections(List<Edge> edges, SegmentIntersector si, bool testAllSegments) {
    if (testAllSegments) {
      add3(edges, null);
    } else {
      add(edges);
    }

    computeIntersections3(si);
  }

  @override
  void computeIntersections2(List<Edge> edges0, List<Edge> edges1, SegmentIntersector si) {
    add3(edges0, edges0);
    add3(edges1, edges1);
    computeIntersections3(si);
  }

  void add(List<Edge> edges) {
    for (var edge in edges) {
      add2(edge, edge);
    }
  }

  void add3(List<Edge> edges, Object? edgeSet) {
    for (var edge in edges) {
      add2(edge, edgeSet);
    }
  }

  void add2(Edge edge, Object? edgeSet) {
    final pts = edge.getCoordinates();
    for (int i = 0; i < (pts.length - 1); i++) {
      final ss = SweepLineSegment(edge, i);
      final insertEvent = SweepLineEventG(edgeSet, ss.getMinX(), null);
      events.add(insertEvent);
      events.add(SweepLineEventG.of(ss.getMaxX(), insertEvent));
    }
  }

  void prepareEvents() {
    events.sort();
    int index = 0;
    for (var e in events) {
      if (e.isDelete()) {
        e.getInsertEvent()!.setDeleteEventIndex(index);
      }
      index += 1;
    }
  }

  void computeIntersections3(SegmentIntersector si) {
    nOverlaps = 0;
    prepareEvents();
    int i = 0;
    for (var ev in events) {
      if (ev.isInsert()) {
        processOverlaps(i, ev.getDeleteEventIndex(), ev, si);
      }
      i++;
    }
  }

  void processOverlaps(int start, int end, SweepLineEventG ev0, SegmentIntersector si) {
    SweepLineSegment ss0 = ev0.getObject() as SweepLineSegment;
    for (int i = start; i < end; i++) {
      SweepLineEventG ev1 = events[i];
      if (ev1.isInsert()) {
        SweepLineSegment ss1 = ev1.getObject() as SweepLineSegment;
        if (!ev0.isSameLabel(ev1)) {
          ss0.computeIntersections(ss1, si);
          nOverlaps++;
        }
      }
    }
  }
}

class SweepLineEventG implements Comparable<SweepLineEventG> {
  static const int _kInsert = 1;

  static const int _kDelete = 2;

  Object? _label;

  double _xValue = 0;

  late int _eventType;

  SweepLineEventG? _insertEvent;

  int _deleteEventIndex = 0;

  Object? _obj;

  SweepLineEventG(this._label, this._xValue, this._obj) {
    _eventType = _kInsert;
  }

  SweepLineEventG.of(double x, this._insertEvent) {
    _eventType = _kDelete;
    _xValue = x;
  }

  bool isInsert() {
    return _eventType == _kInsert;
  }

  bool isDelete() {
    return _eventType == _kDelete;
  }

  SweepLineEventG? getInsertEvent() {
    return _insertEvent;
  }

  int getDeleteEventIndex() {
    return _deleteEventIndex;
  }

  void setDeleteEventIndex(int deleteEventIndex) {
    _deleteEventIndex = deleteEventIndex;
  }

  Object? getObject() {
    return _obj;
  }

  bool isSameLabel(SweepLineEventG ev) {
    if (_label == null) {
      return false;
    }

    return _label == ev._label;
  }

  @override
  int compareTo(SweepLineEventG pe) {
    if (_xValue < pe._xValue) {
      return -1;
    }

    if (_xValue > pe._xValue) {
      return 1;
    }

    if (_eventType < pe._eventType) {
      return -1;
    }

    if (_eventType > pe._eventType) {
      return 1;
    }

    return 0;
  }
}
