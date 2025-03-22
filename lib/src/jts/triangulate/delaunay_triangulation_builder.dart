 import 'package:d_util/d_util.dart';
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

    Array<Coordinate> coords = geom.getCoordinates();
    return unique(coords);
  }

  static CoordinateList unique(Array<Coordinate> coords) {
    Array<Coordinate> coordsCopy = CoordinateArrays.copyDeep(coords);
    coordsCopy.sort();
    CoordinateList coordList = CoordinateList.of2(coordsCopy, false);
    return coordList;
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
      env.expandToInclude(coord);
    }
    return env;
  }

  late CoordinateList siteCoords;

  double tolerance = 0.0;

  QuadEdgeSubdivision? subdiv;

  void setSites2(Geometry geom) {
    siteCoords = extractUniqueCoordinates(geom);
  }

  void setSites(List<Coordinate> coords) {
    siteCoords = unique(CoordinateArrays.toCoordinateArray(coords));
  }

  void setTolerance(double tolerance) {
    this.tolerance = tolerance;
  }

  void create() {
    if (subdiv != null) return;

    Envelope siteEnv = envelope(siteCoords.rawList);
    final vertices = toVertices(siteCoords.rawList);
    subdiv = QuadEdgeSubdivision(siteEnv, tolerance);
    final triangulator = IncrementalDelaunayTriangulator(subdiv!);
    triangulator.insertSites(vertices);
  }

  QuadEdgeSubdivision getSubdivision() {
    create();
    return subdiv!;
  }

  Geometry getEdges(GeometryFactory geomFact) {
    create();
    return subdiv!.getEdges2(geomFact);
  }

  Geometry getTriangles(GeometryFactory geomFact) {
    create();
    return subdiv!.getTriangles2(geomFact);
  }
}
