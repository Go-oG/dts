import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'polygonize_directed_edge.dart';
import 'polygonize_edge.dart';

class EdgeRingO {
  static EdgeRingO? findEdgeRingContaining(EdgeRingO testEr, List<EdgeRingO> erList) {
    EdgeRingO? minContainingRing;
    for (EdgeRingO edgeRing in erList) {
      if (edgeRing.contains(testEr)) {
        if ((minContainingRing == null) ||
            minContainingRing.getEnvelope().contains(edgeRing.getEnvelope())) {
          minContainingRing = edgeRing;
        }
      }
    }
    return minContainingRing;
  }

  static List<PolygonizeDirectedEdge> findDirEdgesInRing(PolygonizeDirectedEdge startDE) {
    PolygonizeDirectedEdge? de = startDE;
    List<PolygonizeDirectedEdge> edges = [];
    do {
      edges.add(de!);
      de = de.next;
      Assert.isTrue2(de != null, "found null DE in ring");
      Assert.isTrue2((de == startDE) || (!de!.isInRing()), "found DE already in ring");
    } while (de != startDE);
    return edges;
  }

  GeometryFactory factory;

  final List<PolygonizeDirectedEdge> _deList = [];

  LinearRing? _ring;

  IndexedPointInAreaLocator? locator;

  Array<Coordinate>? _ringPts;

  List<LinearRing>? _holes;

  EdgeRingO? _shell;

  bool isHole = false;

  bool _isValid = false;

  bool _isProcessed = false;

  bool _isIncludedSet = false;

  bool _isIncluded = false;

  EdgeRingO(this.factory);

  void build(PolygonizeDirectedEdge startDE) {
    PolygonizeDirectedEdge? de = startDE;
    do {
      add(de!);
      de.setRing(this);
      de = de.next;
      Assert.isTrue2(de != null, "found null DE in ring");
      Assert.isTrue2((de == startDE) || (!de!.isInRing()), "found DE already in ring");
    } while (de != startDE);
  }

  void add(covariant PolygonizeDirectedEdge de) {
    _deList.add(de);
  }

  List<PolygonizeDirectedEdge> getEdges() {
    return _deList;
  }

  void computeHole() {
    LinearRing ring = getRing();
    isHole = Orientation.isCCW(ring.getCoordinates());
  }

  void addHole2(LinearRing hole) {
    _holes ??= [];
    _holes!.add(hole);
  }

  void addHole(EdgeRingO holeER) {
    holeER.setShell(this);
    LinearRing hole = holeER.getRing();
    _holes ??= [];
    _holes!.add(hole);
  }

  Polygon getPolygon() {
    Array<LinearRing>? holeLR;
    if (_holes != null) {
      holeLR = _holes!.toArray();
    }
    Polygon poly = factory.createPolygon(_ring, holeLR);
    return poly;
  }

  bool isValid() {
    return _isValid;
  }

  void computeValid() {
    getCoordinates();
    if (_ringPts!.length <= 3) {
      _isValid = false;
      return;
    }
    getRing();
    _isValid = _ring!.isValid();
  }

  bool isIncludedSet() {
    return _isIncludedSet;
  }

  bool isIncluded() {
    return _isIncluded;
  }

  void setIncluded(bool isIncluded) {
    _isIncluded = isIncluded;
    _isIncludedSet = true;
  }

  PointOnGeometryLocator getLocator() {
    locator ??= IndexedPointInAreaLocator(getRing());
    return locator!;
  }

  int locate(Coordinate pt) {
    return getLocator().locate(pt);
  }

  bool contains(EdgeRingO ring) {
    Envelope env = getEnvelope();
    Envelope testEnv = ring.getEnvelope();
    if (!env.containsProperly(testEnv)) {
      return false;
    }

    return isPointInOrOut(ring);
  }

  bool isPointInOrOut(EdgeRingO ring) {
    for (Coordinate pt in ring.getCoordinates()) {
      int loc = locate(pt);
      if (loc == Location.interior) {
        return true;
      }
      if (loc == Location.exterior) {
        return false;
      }
    }
    return false;
  }

  Array<Coordinate> getCoordinates() {
    if (_ringPts == null) {
      CoordinateList coordList = CoordinateList();
      for (PolygonizeDirectedEdge de in _deList) {
        PolygonizeEdge edge = de.getEdge() as PolygonizeEdge;
        addEdge(edge.getLine().getCoordinates(), de.getEdgeDirection(), coordList);
      }
      _ringPts = coordList.toCoordinateArray();
    }
    return _ringPts!;
  }

  LineString getLineString() {
    getCoordinates();
    return factory.createLineString2(_ringPts);
  }

  LinearRing getRing() {
    if (_ring != null) {
      return _ring!;
    }

    getCoordinates();
    try {
      _ring = factory.createLinearRings(_ringPts);
    } catch (_) {}
    return _ring!;
  }

  Envelope getEnvelope() {
    return getRing().getEnvelopeInternal();
  }

  static void addEdge(Array<Coordinate> coords, bool isForward, CoordinateList coordList) {
    if (isForward) {
      for (int i = 0; i < coords.length; i++) {
        coordList.add3(coords[i], false);
      }
    } else {
      for (int i = coords.length - 1; i >= 0; i--) {
        coordList.add3(coords[i], false);
      }
    }
  }

  void setShell(EdgeRingO shell) {
    _shell = shell;
  }

  bool hasShell() {
    return _shell != null;
  }

  EdgeRingO getShell() {
    if (isHole) return _shell!;
    return this;
  }

  bool isOuterHole() {
    if (!isHole) {
      return false;
    }

    return !hasShell();
  }

  bool isOuterShell() {
    return getOuterHole() != null;
  }

  EdgeRingO? getOuterHole() {
    if (isHole) return null;

    for (int i = 0; i < _deList.size; i++) {
      PolygonizeDirectedEdge de = _deList.get(i);
      EdgeRingO adjRing = (de.getSym() as PolygonizeDirectedEdge).getRing()!;
      if (adjRing.isOuterHole()) {
        return adjRing;
      }
    }
    return null;
  }

  void updateIncluded() {
    if (isHole) return;

    for (int i = 0; i < _deList.size; i++) {
      PolygonizeDirectedEdge de = _deList.get(i);
      EdgeRingO? adjShell = ((de.getSym() as PolygonizeDirectedEdge)).getRing()?.getShell();
      if ((adjShell != null) && adjShell.isIncludedSet()) {
        setIncluded(!adjShell.isIncluded());
        return;
      }
    }
  }

  bool isProcessed() {
    return _isProcessed;
  }

  void setProcessed(bool isProcessed) {
    _isProcessed = isProcessed;
  }
}

class EdgeRingEnvelopeComparator implements CComparator<EdgeRingO> {
  @override
  int compare(EdgeRingO r0, EdgeRingO r1) {
    return r0.getRing().getEnvelope().compareTo(r1.getRing().getEnvelope());
  }
}

class EdgeRingEnvelopeAreaComparator implements CComparator<EdgeRingO> {
  @override
  int compare(EdgeRingO r0, EdgeRingO r1) {
    return Double.compare(
        r0.getRing().getEnvelope().getArea(), r1.getRing().getEnvelope().getArea());
  }
}
