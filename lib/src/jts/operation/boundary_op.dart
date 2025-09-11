import 'dart:collection';

import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';
import 'package:dts/src/jts/geom/multi_point.dart';

import 'counter.dart';

class BoundaryOp {
  static Geometry? getBoundary2(Geometry g, [BoundaryNodeRule? bnRule]) {
    BoundaryOp bop = BoundaryOp(g, bnRule);
    return bop.getBoundary();
  }

  static bool hasBoundary(Geometry geom, BoundaryNodeRule boundaryNodeRule) {
    if (geom.isEmpty()) {
      return false;
    }

    switch (geom.getDimension()) {
      case Dimension.P:
        return false;
      case Dimension.L:
        Geometry boundary = BoundaryOp.getBoundary2(geom, boundaryNodeRule)!;
        return !boundary.isEmpty();
      case Dimension.A:
        return true;
    }
    return true;
  }

  final Geometry geom;
  late final GeometryFactory geomFact;
  late BoundaryNodeRule _bnRule;
  late Map<Coordinate, Counter> _endpointMap;

  BoundaryOp(this.geom, [BoundaryNodeRule? bnRule]) {
    geomFact = geom.factory;
    _bnRule = bnRule ?? BoundaryNodeRule.mod2BR;
  }

  Geometry? getBoundary() {
    final geom = this.geom;
    if (geom is LineString) {
      return boundaryLineString(geom);
    }

    if (geom is MultiLineString) {
      return boundaryMultiLineString(geom);
    }

    return geom.getBoundary();
  }

  MultiPoint getEmptyMultiPoint() {
    return geomFact.createMultiPoint();
  }

  Geometry boundaryMultiLineString(MultiLineString mLine) {
    if (geom.isEmpty()) {
      return getEmptyMultiPoint();
    }
    List<Coordinate> bdyPts = computeBoundaryCoordinates(mLine);
    if (bdyPts.length == 1) {
      return geomFact.createPoint2(bdyPts[0]);
    }
    return geomFact.createMultiPoint4(bdyPts);
  }

  List<Coordinate> computeBoundaryCoordinates(MultiLineString mLine) {
    List<Coordinate> bdyPts = [];
    _endpointMap = SplayTreeMap();
    for (int i = 0; i < mLine.getNumGeometries(); i++) {
      LineString line = mLine.getGeometryN(i);
      if (line.getNumPoints() == 0) {
        continue;
      }

      addEndpoint(line.getCoordinateN(0));
      addEndpoint(line.getCoordinateN(line.getNumPoints() - 1));
    }
    for (var entry in _endpointMap.entries) {
      Counter counter = entry.value;
      int valence = counter.count;
      if (_bnRule.isInBoundary(valence)) {
        bdyPts.add(entry.key);
      }
    }
    return bdyPts;
  }

  void addEndpoint(Coordinate pt) {
    Counter? counter = _endpointMap[pt];
    if (counter == null) {
      counter = Counter();
      _endpointMap[pt] = counter;
    }
    counter.count++;
  }

  Geometry? boundaryLineString(LineString line) {
    if (geom.isEmpty()) {
      return getEmptyMultiPoint();
    }
    if (line.isClosed()) {
      if (_bnRule.isInBoundary(2)) {
        return line.getStartPoint();
      } else {
        return geomFact.createMultiPoint();
      }
    }
    return geomFact
        .createMultiPoint([line.getStartPoint()!, line.getEndPoint()!]);
  }
}
