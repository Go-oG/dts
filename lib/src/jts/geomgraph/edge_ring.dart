 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/algorithm/point_location.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'edge.dart';
import 'label.dart';
import 'node.dart';

abstract class EdgeRing {
  DirectedEdge? startDe;

  int _maxNodeDegree = -1;

  List edges = [];

  final List<Coordinate> _pts = [];

  final Label _label = Label.of(Location.none);

  LinearRing? _ring;

  bool _isHole = false;

  EdgeRing? _shell;

  final List<EdgeRing> _holes = [];

  GeometryFactory geometryFactory;

  EdgeRing(DirectedEdge start, this.geometryFactory) {
    computePoints(start);
    computeRing();
  }

  bool isIsolated() {
    return _label.getGeometryCount() == 1;
  }

  bool isHole() {
    return _isHole;
  }

  Coordinate getCoordinate(int i) {
    return _pts.get(i);
  }

  LinearRing? getLinearRing() {
    return _ring;
  }

  Label getLabel() {
    return _label;
  }

  bool isShell() {
    return _shell == null;
  }

  EdgeRing? getShell() {
    return _shell;
  }

  void setShell(EdgeRing? shell) {
    _shell = shell;
    if (shell != null) {
      shell.addHole(this);
    }
  }

  void addHole(EdgeRing ring) {
    _holes.add(ring);
  }

  Polygon toPolygon(GeometryFactory geometryFactory) {
    Array<LinearRing> holeLR = Array(_holes.length);
    int i = 0;
    for (var e in _holes) {
      holeLR[i] = e.getLinearRing()!;
      i++;
    }

    return geometryFactory.createPolygon(getLinearRing(), holeLR);
  }

  void computeRing() {
    if (_ring != null) return;

    Array<Coordinate> coord = _pts.toArray();

    _ring = geometryFactory.createLinearRing2(coord);
    _isHole = Orientation.isCCW(_ring!.getCoordinates());
  }

  DirectedEdge? getNext(DirectedEdge de);

  void setEdgeRing(DirectedEdge de, EdgeRing er);

  List getEdges() {
    return edges;
  }

  void computePoints(DirectedEdge? start) {
    startDe = start;
    DirectedEdge? de = start;
    bool isFirstEdge = true;
    do {
      if (de == null) throw TopologyException("Found null DirectedEdge");

      if (de.getEdgeRing() == this) {
        throw TopologyException("Directed Edge visited twice during ring-building at ${de.getCoordinate()}");
      }

      edges.add(de);
      Label label = de.getLabel()!;
      Assert.isTrue(label.isArea());
      mergeLabel(label);
      addPoints(de.getEdge(), de.isForward, isFirstEdge);
      isFirstEdge = false;
      setEdgeRing(de, this);
      de = getNext(de);
    } while (de != startDe);
  }

  int getMaxNodeDegree() {
    if (_maxNodeDegree < 0) computeMaxNodeDegree();

    return _maxNodeDegree;
  }

  void computeMaxNodeDegree() {
    _maxNodeDegree = 0;
    DirectedEdge? de = startDe!;
    do {
      Node node = de!.getNode();
      int degree = ((node.getEdges() as DirectedEdgeStar)).getOutgoingDegree2(this);
      if (degree > _maxNodeDegree) _maxNodeDegree = degree;
      de = getNext(de);
    } while (de != startDe);
    _maxNodeDegree *= 2;
  }

  void setInResult() {
    DirectedEdge? de = startDe;
    do {
      de!.getEdge().isInResult = true;
      de = de.getNext();
    } while (de != startDe);
  }

  void mergeLabel(Label deLabel) {
    mergeLabel2(deLabel, 0);
    mergeLabel2(deLabel, 1);
  }

  void mergeLabel2(Label deLabel, int geomIndex) {
    int loc = deLabel.getLocation2(geomIndex, Position.right);
    if (loc == Location.none) return;

    if (_label.getLocation(geomIndex) == Location.none) {
      _label.setLocation(geomIndex, loc);
      return;
    }
  }

  void addPoints(Edge edge, bool isForward, bool isFirstEdge) {
    Array<Coordinate> edgePts = edge.getCoordinates();
    if (isForward) {
      int startIndex = 1;
      if (isFirstEdge) startIndex = 0;

      for (int i = startIndex; i < edgePts.length; i++) {
        _pts.add(edgePts[i]);
      }
    } else {
      int startIndex = edgePts.length - 2;
      if (isFirstEdge) startIndex = edgePts.length - 1;

      for (int i = startIndex; i >= 0; i--) {
        _pts.add(edgePts[i]);
      }
    }
  }

  bool containsPoint(Coordinate p) {
    LinearRing shell = getLinearRing()!;
    Envelope env = shell.getEnvelopeInternal();
    if (!env.contains(p)) return false;

    if (!PointLocation.isInRing(p, shell.getCoordinates())) return false;

    for (var hole in _holes) {
      if (hole.containsPoint(p)) return false;
    }
    return true;
  }
}
