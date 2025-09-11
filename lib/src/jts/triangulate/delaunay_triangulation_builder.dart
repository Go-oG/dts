import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/triangulate/quadedge/quad_edge_subdivision.dart';
import 'package:dts/src/jts/triangulate/quadedge/vertex.dart';

import 'incremental_delaunay_triangulator.dart';

class DelaunayTriangulationBuilder {
  static CoordinateList extractUniqueCoordinates(Geometry? geom) {
    if (geom == null) {
      return CoordinateList();
    }
    return unique(geom.getCoordinates());
  }

  static CoordinateList unique(List<Coordinate> coords) {
    List<Coordinate> coordsCopy = CoordinateArrays.copyDeep(coords);
    coordsCopy.sort();
    return CoordinateList(coordsCopy, false);
  }

  static List<Vertex> toVertices(List<Coordinate> coords) {
    List<Vertex> verts = [];
    for (var i = coords.iterator; i.moveNext();) {
      Coordinate coord = i.current;
      verts.add(Vertex.of(coord));
    }
    return verts;
  }

  static Envelope envelope(List<Coordinate> coords) {
    Envelope env = Envelope();
    for (var i = coords.iterator; i.moveNext();) {
      Coordinate coord = i.current;
      env.expandToIncludeCoordinate(coord);
    }
    return env;
  }

  late CoordinateList siteCoords;

  double tolerance = 0.0;

  void setSites2(Geometry geom) => siteCoords = extractUniqueCoordinates(geom);

  void setSites(List<Coordinate> coords) => siteCoords = unique(coords);

  void setTolerance(double tolerance) => this.tolerance = tolerance;

  QuadEdgeSubdivision? _subDiv;

  QuadEdgeSubdivision get subDiv {
    if (_subDiv != null) {
      return _subDiv!;
    }
    Envelope siteEnv = envelope(siteCoords.rawList);
    final vertices = toVertices(siteCoords.rawList);
    _subDiv = QuadEdgeSubdivision(siteEnv, tolerance);
    final triangulator = IncrementalDelaunayTriangulator(_subDiv!);
    triangulator.insertSites(vertices);
    return _subDiv!;
  }

  QuadEdgeSubdivision getSubdivision() => subDiv;

  Geometry getEdges(GeometryFactory geomFact) => subDiv.getEdges2(geomFact);

  Geometry getTriangles(GeometryFactory geomFact) =>
      subDiv.getTriangles2(geomFact);
}
