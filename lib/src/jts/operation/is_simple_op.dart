import 'dart:collection';

import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';
import 'package:dts/src/jts/geom/multi_point.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygonal.dart';
import 'package:dts/src/jts/geom/util/linear_component_extracter.dart';
import 'package:dts/src/jts/geomgraph/geometry_graph.dart';
import 'package:dts/src/jts/geomgraph/index/segment_intersector.dart';

class IsSimpleOpO {
  Geometry? inputGeom;
  bool _isClosedEndpointsInInterior = true;

  Coordinate? _nonSimpleLocation;

  IsSimpleOpO([this.inputGeom, BoundaryNodeRule? boundaryNodeRule]) {
    if (boundaryNodeRule != null) {
      _isClosedEndpointsInInterior = !boundaryNodeRule.isInBoundary(2);
    }
  }

  bool isSimple() {
    _nonSimpleLocation = null;
    return computeSimple(inputGeom!);
  }

  bool computeSimple(Geometry geom) {
    _nonSimpleLocation = null;
    if (geom.isEmpty()) {
      return true;
    }

    if (geom is LineString) return isSimpleLinearGeometry(geom);

    if (geom is MultiLineString) return isSimpleLinearGeometry(geom);

    if (geom is MultiPoint) return isSimpleMultiPoint(geom);

    if (geom is Polygonal) {
      return isSimplePolygonal(geom);
    }

    if (geom is GeometryCollection) return isSimpleGeometryCollection(geom);

    return true;
  }

  Coordinate? getNonSimpleLocation() {
    return _nonSimpleLocation;
  }

  bool isSimple2(LineString geom) {
    return isSimpleLinearGeometry(geom);
  }

  bool isSimple4(MultiLineString geom) {
    return isSimpleLinearGeometry(geom);
  }

  bool isSimple3(MultiPoint mp) {
    return isSimpleMultiPoint(mp);
  }

  bool isSimpleMultiPoint(MultiPoint mp) {
    if (mp.isEmpty()) {
      return true;
    }

    Set points = SplayTreeSet();
    for (int i = 0; i < mp.getNumGeometries(); i++) {
      Point pt = mp.getGeometryN(i);
      Coordinate p = pt.getCoordinate()!;
      if (points.contains(p)) {
        _nonSimpleLocation = p;
        return false;
      }
      points.add(p);
    }
    return true;
  }

  bool isSimplePolygonal(Geometry geom) {
    final rings = LinearComponentExtracter.getLines(geom);
    for (var i in rings) {
      LinearRing ring = i as LinearRing;
      if (!isSimpleLinearGeometry(ring)) return false;
    }
    return true;
  }

  bool isSimpleGeometryCollection(Geometry geom) {
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry comp = geom.getGeometryN(i);
      if (!computeSimple(comp)) {
        return false;
      }
    }
    return true;
  }

  bool isSimpleLinearGeometry(Geometry geom) {
    if (geom.isEmpty()) {
      return true;
    }

    GeometryGraph graph = GeometryGraph.of(0, geom);
    LineIntersector li = RobustLineIntersector();
    SegmentIntersector si = graph.computeSelfNodes(li, true);
    if (!si.hasIntersection) {
      return true;
    }

    if (si.hasProperIntersection()) {
      _nonSimpleLocation = si.properIntersectionPoint;
      return false;
    }
    if (hasNonEndpointIntersection(graph)) {
      return false;
    }

    if (_isClosedEndpointsInInterior) {
      if (hasClosedEndpointIntersection(graph)) {
        return false;
      }
    }
    return true;
  }

  bool hasNonEndpointIntersection(GeometryGraph graph) {
    for (var e in graph.getEdgeIterator()) {
      int maxSegmentIndex = e.getMaximumSegmentIndex();
      for (var ei in e.getEdgeIntersectionList().iterator()) {
        if (!ei.isEndPoint(maxSegmentIndex)) {
          _nonSimpleLocation = ei.getCoordinate();
          return true;
        }
      }
    }
    return false;
  }

  bool hasClosedEndpointIntersection(GeometryGraph graph) {
    Map<Coordinate, EndpointInfo> endPoints = SplayTreeMap();
    for (var e in graph.getEdgeIterator()) {
      bool isClosed = e.isClosed();
      Coordinate p0 = e.getCoordinate2(0);
      addEndpoint(endPoints, p0, isClosed);
      Coordinate p1 = e.getCoordinate2(e.getNumPoints() - 1);
      addEndpoint(endPoints, p1, isClosed);
    }
    for (var eiInfo in endPoints.values) {
      if (eiInfo.isClosed && (eiInfo.degree != 2)) {
        _nonSimpleLocation = eiInfo.getCoordinate();
        return true;
      }
    }
    return false;
  }

  void addEndpoint(Map<Coordinate, EndpointInfo> endPoints, Coordinate p, bool isClosed) {
    EndpointInfo? eiInfo = endPoints[p];
    if (eiInfo == null) {
      eiInfo = EndpointInfo(p);
      endPoints[p] = eiInfo;
    }
    eiInfo.addEndpoint(isClosed);
  }
}

class EndpointInfo {
  Coordinate pt;

  bool isClosed = false;

  int degree = 0;

  EndpointInfo(this.pt);

  Coordinate getCoordinate() {
    return pt;
  }

  void addEndpoint(bool isClosed) {
    degree++;
    this.isClosed |= isClosed;
  }
}
