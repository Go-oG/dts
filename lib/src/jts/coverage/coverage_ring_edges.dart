 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'coverage_boundary_segment_finder.dart';
import 'coverage_edge.dart';
import 'vertex_ring_counter.dart';

class CoverageRingEdges {
  static CoverageRingEdges create(Array<Geometry> coverage) {
    CoverageRingEdges edges = CoverageRingEdges(coverage);
    return edges;
  }

  Array<Geometry> coverage;

  final Map<LinearRing, List<CoverageEdge>> _ringEdgesMap = {};

  final List<CoverageEdge> _edges = [];

  CoverageRingEdges(this.coverage) {
    _build();
  }

  List<CoverageEdge> getEdges() {
    return _edges;
  }

  void _build() {
    Set<Coordinate> nodes = _findMultiRingNodes(coverage);
    Set<LineSegment> boundarySegs = CoverageBoundarySegmentFinder.findBoundarySegments(coverage);
    nodes.addAll(_findBoundaryNodes(boundarySegs));
    Map<LineSegment, CoverageEdge> uniqueEdgeMap = {};
    for (int i = 0; i < coverage.length; i++) {
      Geometry geom = coverage[i];
      int indexLargest = _findLargestPolygonIndex(geom);
      for (int ipoly = 0; ipoly < geom.getNumGeometries(); ipoly++) {
        Polygon poly = (geom.getGeometryN(ipoly) as Polygon);
        if (poly.isEmpty()) {
          continue;
        }

        bool isPrimary = ipoly == indexLargest;
        LinearRing shell = poly.getExteriorRing();
        _addRingEdges(i, shell, isPrimary, nodes, boundarySegs, uniqueEdgeMap);
        for (int ihole = 0; ihole < poly.getNumInteriorRing(); ihole++) {
          LinearRing hole = poly.getInteriorRingN(ihole);
          if (hole.isEmpty()) {
            continue;
          }

          _addRingEdges(i, hole, false, nodes, boundarySegs, uniqueEdgeMap);
        }
      }
    }
  }

  int _findLargestPolygonIndex(Geometry geom) {
    if (geom is Polygon) {
      return 0;
    }

    int indexLargest = -1;
    double areaLargest = -1;
    for (int ipoly = 0; ipoly < geom.getNumGeometries(); ipoly++) {
      Polygon poly = ((geom.getGeometryN(ipoly) as Polygon));
      double area = poly.getArea();
      if (area > areaLargest) {
        areaLargest = area;
        indexLargest = ipoly;
      }
    }
    return indexLargest;
  }

  void _addRingEdges(
    int index,
    LinearRing ring,
    bool isPrimary,
    Set<Coordinate> nodes,
    Set<LineSegment> boundarySegs,
    Map<LineSegment, CoverageEdge> uniqueEdgeMap,
  ) {
    _addBoundaryInnerNodes(ring, boundarySegs, nodes);
    List<CoverageEdge> ringEdges = _extractRingEdges(index, ring, isPrimary, uniqueEdgeMap, nodes)!;
    _ringEdgesMap.put(ring, ringEdges);
  }

  void _addBoundaryInnerNodes(LinearRing ring, Set<LineSegment> boundarySegs, Set<Coordinate> nodes) {
    CoordinateSequence seq = ring.getCoordinateSequence();
    bool isBdyLast = CoverageBoundarySegmentFinder.isBoundarySegment(boundarySegs, seq, seq.size() - 2);
    bool isBdyPrev = isBdyLast;
    for (int i = 0; i < (seq.size() - 1); i++) {
      bool isBdy = CoverageBoundarySegmentFinder.isBoundarySegment(boundarySegs, seq, i);
      if (isBdy != isBdyPrev) {
        Coordinate nodePt = seq.getCoordinate(i);
        nodes.add(nodePt);
      }
      isBdyPrev = isBdy;
    }
  }

  List<CoverageEdge>? _extractRingEdges(
    int index,
    LinearRing ring,
    bool isPrimary,
    Map<LineSegment, CoverageEdge> uniqueEdgeMap,
    Set<Coordinate> nodes,
  ) {
    List<CoverageEdge> ringEdges = [];
    Array<Coordinate> pts = ring.getCoordinates();
    pts = CoordinateArrays.removeRepeatedPoints(pts);
    if (pts.length < 3) {
      return null;
    }

    int first = _findNextNodeIndex(pts, -1, nodes);
    if (first < 0) {
      CoverageEdge edge = _createEdge(pts, -1, -1, index, isPrimary, uniqueEdgeMap);
      ringEdges.add(edge);
    } else {
      int start = first;
      int end = start;
      bool isEdgePrimary = true;
      do {
        end = _findNextNodeIndex(pts, start, nodes);
        if (end == start) {
          isEdgePrimary = isPrimary;
        }
        CoverageEdge edge = _createEdge(pts, start, end, index, isEdgePrimary, uniqueEdgeMap);
        ringEdges.add(edge);
        start = end;
      } while (end != first);
    }
    return ringEdges;
  }

  CoverageEdge _createEdge(
    Array<Coordinate> ring,
    int start,
    int end,
    int index,
    bool isPrimary,
    Map<LineSegment, CoverageEdge> uniqueEdgeMap,
  ) {
    CoverageEdge edge;
    LineSegment edgeKey = (end == start) ? CoverageEdge.key(ring) : CoverageEdge.key2(ring, start, end);
    if (uniqueEdgeMap.containsKey(edgeKey)) {
      edge = uniqueEdgeMap.get(edgeKey)!;
      edge.setPrimary(isPrimary);
    } else {
      if (start < 0) {
        edge = CoverageEdge.createEdge(ring, isPrimary);
      } else {
        edge = CoverageEdge.createEdge2(ring, start, end, isPrimary);
      }
      uniqueEdgeMap.put(edgeKey, edge);
      _edges.add(edge);
    }
    edge.addIndex(index);
    edge.incRingCount();
    return edge;
  }

  int _findNextNodeIndex(Array<Coordinate> ring, int start, Set<Coordinate> nodes) {
    int index = start;
    bool isScanned0 = false;
    do {
      index = _next(index, ring);
      if (index == 0) {
        if ((start < 0) && isScanned0) {
          return -1;
        }

        isScanned0 = true;
      }
      Coordinate pt = ring[index];
      if (nodes.contains(pt)) {
        return index;
      }
    } while (index != start);
    return -1;
  }

  static int _next(int index, Array<Coordinate> ring) {
    index = index + 1;
    if (index >= (ring.length - 1)) {
      index = 0;
    }

    return index;
  }

  Set<Coordinate> _findMultiRingNodes(Array<Geometry> coverage) {
    Map<Coordinate, int> vertexRingCount = VertexRingCounter.count(coverage);
    Set<Coordinate> nodes = <Coordinate>{};
    for (Coordinate v in vertexRingCount.keys) {
      if (vertexRingCount.get(v)! >= 3) {
        nodes.add(v);
      }
    }
    return nodes;
  }

  Set<Coordinate> _findBoundaryNodes(Set<LineSegment> boundarySegments) {
    Map<Coordinate, int> counter = {};
    for (LineSegment seg in boundarySegments) {
      counter.put(seg.p0, counter.getOrDefault(seg.p0, 0) + 1);
      counter.put(seg.p1, counter.getOrDefault(seg.p1, 0) + 1);
    }
    return counter.keys.where((e) => counter.get(e)! > 2).toSet();
  }

  Array<Geometry> buildCoverage() {
    Array<Geometry> result = Array<Geometry>(coverage.length);
    for (int i = 0; i < coverage.length; i++) {
      result[i] = _buildPolygonal(coverage[i]);
    }
    return result;
  }

  Geometry _buildPolygonal(Geometry geom) {
    if (geom is MultiPolygon) {
      return _buildMultiPolygon(geom);
    } else {
      return _buildPolygon((geom) as Polygon);
    }
  }

  Geometry _buildMultiPolygon(MultiPolygon geom) {
    List<Polygon> polyList = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Polygon poly = _buildPolygon(geom.getGeometryN(i));
      polyList.add(poly);
    }
    if (polyList.size == 1) {
      return polyList.get(0);
    }
    Array<Polygon> polys = GeometryFactory.toPolygonArray(polyList);
    return geom.factory.createMultiPolygon(polys);
  }

  Polygon _buildPolygon(Polygon polygon) {
    LinearRing shell = _buildRing(polygon.getExteriorRing())!;
    if (polygon.getNumInteriorRing() == 0) {
      return polygon.factory.createPolygon(shell);
    }
    List<LinearRing> holeList = [];
    for (int i = 0; i < polygon.getNumInteriorRing(); i++) {
      LinearRing hole = polygon.getInteriorRingN(i);
      LinearRing newHole = _buildRing(hole)!;
      holeList.add(newHole);
    }
    Array<LinearRing> holes = GeometryFactory.toLinearRingArray(holeList);
    return polygon.factory.createPolygon(shell, holes);
  }

  LinearRing? _buildRing(LinearRing ring) {
    List<CoverageEdge> ringEdges = _ringEdgesMap.get(ring)!;

    bool isRemoved = (ringEdges.size == 1) && (ringEdges.get(0).getCoordinates().isEmpty);
    if (isRemoved) {
      return null;
    }

    CoordinateList ptsList = CoordinateList();
    for (int i = 0; i < ringEdges.size; i++) {
      Coordinate? lastPt = (ptsList.size > 0) ? ptsList.getCoordinate(ptsList.size - 1) : null;
      bool dir = _isEdgeDirForward(ringEdges, i, lastPt!);
      ptsList.add4(ringEdges.get(i).getCoordinates(), false, dir);
    }
    Array<Coordinate> pts = ptsList.toCoordinateArray();
    return ring.factory.createLinearRing2(pts);
  }

  bool _isEdgeDirForward(List<CoverageEdge> ringEdges, int index, Coordinate prevPt) {
    int size = ringEdges.size;
    if (size <= 1) {
      return true;
    }

    if (index == 0) {
      if (size == 2) {
        return true;
      }

      Coordinate endPt0 = ringEdges.get(0).getEndCoordinate();
      return endPt0.equals2D(ringEdges.get(1).getStartCoordinate()) ||
          endPt0.equals2D(ringEdges.get(1).getEndCoordinate());
    }
    return prevPt.equals2D(ringEdges.get(index).getStartCoordinate());
  }
}
