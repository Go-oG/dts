import 'dart:collection';

 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';

import '../geom/coordinate.dart';
import '../util/assert.dart';
import 'noded_segment_string.dart';
import 'segment_node.dart';
import 'segment_string.dart';

class SegmentNodeList {
  Map<SegmentNode, SegmentNode> nodeMap = SplayTreeMap();

  final NodedSegmentString _edge;

  SegmentNodeList(this._edge);

  int size() {
    return nodeMap.length;
  }

  NodedSegmentString getEdge() {
    return _edge;
  }

  SegmentNode add(Coordinate intPt, int segmentIndex) {
    final eiNew = SegmentNode(_edge, intPt, segmentIndex, _edge.getSegmentOctant(segmentIndex));
    final ei = nodeMap.get(eiNew);
    if (ei != null) {
      Assert.isTrue2(ei.coord.equals2D(intPt), "Found equal nodes with different coordinates");
      return ei;
    }
    nodeMap[eiNew] = eiNew;
    return eiNew;
  }

  Iterable<SegmentNode> iterator() {
    return nodeMap.values;
  }

  void addEndpoints() {
    int maxSegIndex = _edge.size() - 1;
    add(_edge.getCoordinate(0), 0);
    add(_edge.getCoordinate(maxSegIndex), maxSegIndex);
  }

  void addCollapsedNodes() {
    List<int> collapsedVertexIndexes = [];
    findCollapsesFromInsertedNodes(collapsedVertexIndexes);
    findCollapsesFromExistingVertices(collapsedVertexIndexes);
    for (var vertexIndex in collapsedVertexIndexes) {
      add(_edge.getCoordinate(vertexIndex), vertexIndex);
    }
  }

  void findCollapsesFromExistingVertices(List collapsedVertexIndexes) {
    for (int i = 0; i < (_edge.size() - 2); i++) {
      Coordinate p0 = _edge.getCoordinate(i);
      Coordinate p1 = _edge.getCoordinate(i + 1);
      Coordinate p2 = _edge.getCoordinate(i + 2);
      if (p0.equals2D(p2)) {
        collapsedVertexIndexes.add(i + 1);
      }
    }
  }

  void findCollapsesFromInsertedNodes(List collapsedVertexIndexes) {
    Array<int> collapsedVertexIndex = Array(1);
    //TODO 校验
    final it = iterator().iterator;
    it.moveNext();
    SegmentNode eiPrev = it.current;

    while (it.moveNext()) {
      SegmentNode ei = it.current;
      bool isCollapsed = findCollapseIndex(eiPrev, ei, collapsedVertexIndex);
      if (isCollapsed) collapsedVertexIndexes.add(collapsedVertexIndex[0]);

      eiPrev = ei;
    }
  }

  bool findCollapseIndex(SegmentNode ei0, SegmentNode ei1, Array<int> collapsedVertexIndex) {
    if (!ei0.coord.equals2D(ei1.coord)) return false;

    int numVerticesBetween = ei1.segmentIndex - ei0.segmentIndex;
    if (!ei1.isInterior()) {
      numVerticesBetween--;
    }
    if (numVerticesBetween == 1) {
      collapsedVertexIndex[0] = ei0.segmentIndex + 1;
      return true;
    }
    return false;
  }

  void addSplitEdges(List<SegmentString> edgeList) {
    addEndpoints();
    addCollapsedNodes();
    var it = iterator().iterator;
    it.moveNext();
    SegmentNode eiPrev = it.current;

    while (it.moveNext()) {
      SegmentNode ei = it.current;
      SegmentString newEdge = createSplitEdge(eiPrev, ei);
      edgeList.add(newEdge);
      eiPrev = ei;
    }
  }

  void checkSplitEdgesCorrectness(List<SegmentString> splitEdges) {
    Array<Coordinate> edgePts = _edge.getCoordinates();
    SegmentString split0 = splitEdges.first;
    Coordinate pt0 = split0.getCoordinate(0);
    if (!pt0.equals2D(edgePts[0])) throw ("bad split edge start point at $pt0");

    SegmentString splitn = splitEdges.last;
    Array<Coordinate> splitnPts = splitn.getCoordinates();
    Coordinate ptn = splitnPts[splitnPts.length - 1];
    if (!ptn.equals2D(edgePts[edgePts.length - 1])) throw ("bad split edge end point at $ptn");
  }

  SegmentString createSplitEdge(SegmentNode ei0, SegmentNode ei1) {
    Array<Coordinate> pts = createSplitEdgePts(ei0, ei1);
    return NodedSegmentString(pts, _edge.getData());
  }

  Array<Coordinate> createSplitEdgePts(SegmentNode ei0, SegmentNode ei1) {
    int npts = (ei1.segmentIndex - ei0.segmentIndex) + 2;
    if (npts == 2) return [Coordinate.of(ei0.coord), Coordinate.of(ei1.coord)].toArray();

    Coordinate lastSegStartPt = _edge.getCoordinate(ei1.segmentIndex);
    bool useIntPt1 = ei1.isInterior() || (!ei1.coord.equals2D(lastSegStartPt));
    if (!useIntPt1) {
      npts--;
    }
    Array<Coordinate> pts = Array(npts);
    int ipt = 0;
    pts[ipt++] = ei0.coord.copy();
    for (int i = ei0.segmentIndex + 1; i <= ei1.segmentIndex; i++) {
      pts[ipt++] = _edge.getCoordinate(i);
    }
    if (useIntPt1) pts[ipt] = ei1.coord.copy();

    return pts;
  }

  Array<Coordinate> getSplitCoordinates() {
    CoordinateList coordList = CoordinateList();
    addEndpoints();
    //TODO 校验
    var it = iterator().iterator;
    it.moveNext();
    SegmentNode eiPrev = it.current;

    while (it.moveNext()) {
      SegmentNode ei = it.current;
      addEdgeCoordinates(eiPrev, ei, coordList);
      eiPrev = ei;
    }
    return coordList.toCoordinateArray();
  }

  void addEdgeCoordinates(SegmentNode ei0, SegmentNode ei1, CoordinateList coordList) {
    Array<Coordinate> pts = createSplitEdgePts(ei0, ei1);
    coordList.add2(pts, false);
  }
}
