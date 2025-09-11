import 'dart:core';

import 'package:dts/src/jts/algorithm/point_location.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';

class OuterShellsExtracter {
  static List<LinearRing> extractShells(Geometry polygons) {
    return OuterShellsExtracter(polygons)._extractShells();
  }

  final Geometry _polygons;

  OuterShellsExtracter(this._polygons);

  List<LinearRing> _extractShells() {
    List<LinearRing> shells = _extractShellRings(_polygons);
    shells.sort(_EnvelopeAreaComparator().compare);
    List<LinearRing> outerShells = [];

    for (var shell in shells.reversed) {
      if (outerShells.isEmpty || _isOuter(shell, outerShells)) {
        outerShells.add(shell);
      }
    }
    return outerShells;
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

  static List<LinearRing> _extractShellRings(Geometry polygons) {
    List<LinearRing> rings = [];
    final c = polygons.getNumGeometries();
    for (int i = 0; i < c; i++) {
      Polygon consPoly = ((polygons.getGeometryN(i) as Polygon));
      rings.add(consPoly.getExteriorRing().copy() as LinearRing);
    }
    return rings;
  }
}

class _EnvelopeAreaComparator {
  int compare(Geometry o1, Geometry o2) {
    double a1 = o1.getEnvelopeInternal().area;
    double a2 = o2.getEnvelopeInternal().area;
    return a1.compareTo(a2);
  }
}
