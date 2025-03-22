 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/point_location.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'node_section.dart';
import 'node_sections.dart';
import 'relate_geometry.dart';

class AdjacentEdgeLocator {
  List<Array<Coordinate>>? _ringList;

  AdjacentEdgeLocator(Geometry geom) {
    init(geom);
  }

  void init(Geometry geom) {
    if (geom.isEmpty()) return;
    _ringList = [];
    addRings(geom, _ringList!);
  }

  int locate(Coordinate p) {
    final sections = NodeSections(p);
    for (Array<Coordinate> ring in _ringList!) {
      addSections(p, ring, sections);
    }
    final node = sections.createNode();
    return node.hasExteriorEdge(true) ? Location.boundary : Location.interior;
  }

  void addSections(Coordinate p, Array<Coordinate> ring, NodeSections sections) {
    for (int i = 0; i < (ring.length - 1); i++) {
      Coordinate p0 = ring[i];
      Coordinate pnext = ring[i + 1];
      if (p.equals2D(pnext)) {
        continue;
      } else if (p.equals2D(p0)) {
        int iprev = (i > 0) ? i - 1 : ring.length - 2;
        Coordinate pprev = ring[iprev];
        sections.addNodeSection(createSection(p, pprev, pnext));
      } else if (PointLocation.isOnSegment(p, p0, pnext)) {
        sections.addNodeSection(createSection(p, p0, pnext));
      }
    }
  }

  NodeSection createSection(Coordinate p, Coordinate prev, Coordinate next) {
    if ((prev.distance(p) == 0) || (next.distance(p) == 0)) {
      print("Found zero-length section segment");
    }
    return NodeSection(true, Dimension.A, 1, 0, null, false, prev, p, next);
  }

  void addRings(Geometry geom, List<Array<Coordinate>> ringList2) {
    if (geom is Polygon) {
      Polygon poly = geom;
      LinearRing shell = poly.getExteriorRing();
      addRing(shell, true);
      for (int i = 0; i < poly.getNumInteriorRing(); i++) {
        LinearRing hole = poly.getInteriorRingN(i);
        addRing(hole, false);
      }
    } else if (geom is GeometryCollection) {
      for (int i = 0; i < geom.getNumGeometries(); i++) {
        addRings(geom.getGeometryN(i), _ringList!);
      }
    }
  }

  void addRing(LinearRing ring, bool requireCW) {
    Array<Coordinate> pts = RelateGeometry.orient(ring.getCoordinates(), requireCW);
    _ringList!.add(pts);
  }
}
