import 'dart:core';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/point_location.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';

class OuterShellsExtracter {
  static Array<LinearRing> extractShells(Geometry polygons) {
    return OuterShellsExtracter(polygons)._extractShells();
  }

  final Geometry _polygons;

  OuterShellsExtracter(this._polygons);

  Array<LinearRing> _extractShells() {
    Array<LinearRing> shells = _extractShellRings(_polygons);
    shells.sort(_EnvelopeAreaComparator().compare);
    List<LinearRing> outerShells = [];

    for (var shell in shells.reversed) {
      if ((outerShells.size == 0) || _isOuter(shell, outerShells)) {
        outerShells.add(shell);
      }
    }
    return GeometryFactory.toLinearRingArray(outerShells);
  }

  bool _isOuter(LinearRing shell, List<LinearRing> outerShells) {
    for (LinearRing outShell in outerShells) {
      if (_covers(outShell, shell)) {
        return false;
      }
    }
    return true;
  }

  bool _covers(LinearRing shellA, LinearRing shellB) {
    if (!shellA.getEnvelopeInternal().covers(shellB.getEnvelopeInternal())) {
      return false;
    }

    if (_isPointInRing(shellB, shellA)) {
      return true;
    }

    return false;
  }

  bool _isPointInRing(LinearRing shell, LinearRing shellRing) {
    Coordinate pt = shell.getCoordinate()!;
    return PointLocation.isInRing(pt, shellRing.getCoordinates());
  }

  static Array<LinearRing> _extractShellRings(Geometry polygons) {
    Array<LinearRing> rings = Array<LinearRing>(polygons.getNumGeometries());
    for (int i = 0; i < polygons.getNumGeometries(); i++) {
      Polygon consPoly = ((polygons.getGeometryN(i) as Polygon));
      rings[i] = ((consPoly.getExteriorRing().copy() as LinearRing));
    }
    return rings;
  }
}

class _EnvelopeAreaComparator {
  int compare(Geometry o1, Geometry o2) {
    double a1 = o1.getEnvelopeInternal().area;
    double a2 = o2.getEnvelopeInternal().area;
    return Double.compare(a1, a2);
  }
}
