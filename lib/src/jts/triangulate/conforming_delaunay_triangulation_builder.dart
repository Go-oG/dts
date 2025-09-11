import 'dart:collection';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/util/linear_component_extracter.dart';
import 'package:dts/src/jts/triangulate/quadedge/quad_edge_subdivision.dart';
import 'package:dts/src/jts/triangulate/quadedge/vertex.dart';

import '../geom/coordinate_list.dart';
import 'conforming_delaunay_triangulator.dart';
import 'constraint_vertex.dart';
import 'delaunay_triangulation_builder.dart';
import 'segment.dart';

class ConformingDelaunayTriangulationBuilder {
  late CoordinateList _siteCoords;

  Geometry? _constraintLines;

  double _tolerance = 0.0;

  QuadEdgeSubdivision? _subDiv;

  final Map<Coordinate, Vertex> _constraintVertexMap = SplayTreeMap();

  void setSites(Geometry geom) {
    _siteCoords = DelaunayTriangulationBuilder.extractUniqueCoordinates(geom);
  }

  void setConstraints(Geometry constraintLines) {
    _constraintLines = constraintLines;
  }

  void setTolerance(double tolerance) {
    _tolerance = tolerance;
  }

  void create() {
    if (_subDiv != null) return;

    Envelope siteEnv =
        DelaunayTriangulationBuilder.envelope(_siteCoords.rawList);
    List<Segment> segments = [];
    if (_constraintLines != null) {
      siteEnv.expandToInclude(_constraintLines!.getEnvelopeInternal());
      createVertices(_constraintLines!);
      segments = createConstraintSegments(_constraintLines!);
    }
    List<Vertex> sites = createSiteVertices(_siteCoords);
    final cdt = ConformingDelaunayTriangulator(sites, _tolerance);
    cdt.setConstraints(segments, _constraintVertexMap.values.toList());
    cdt.formInitialDelaunay();
    cdt.enforceConstraints();
    _subDiv = cdt.getSubdivision();
  }

  List<Vertex> createSiteVertices(CoordinateList coords) {
    List<ConstraintVertex> verts = [];
    for (Iterator i = coords.rawList.iterator; i.moveNext();) {
      Coordinate coord = i.current;
      if (_constraintVertexMap.containsKey(coord)) continue;
      verts.add(ConstraintVertex(coord));
    }
    return verts;
  }

  void createVertices(Geometry geom) {
    final coords = geom.getCoordinates();
    for (int i = 0; i < coords.length; i++) {
      Vertex v = ConstraintVertex(coords[i]);
      _constraintVertexMap.put(coords[i], v);
    }
  }

  static List<Segment> createConstraintSegments(Geometry geom) {
    final lines = LinearComponentExtracter.getLines(geom);
    List<Segment> constraintSegs = [];
    for (Iterator i = lines.iterator; i.moveNext();) {
      createConstraintSegments2(i.current, constraintSegs);
    }
    return constraintSegs;
  }

  static void createConstraintSegments2(
      LineString line, List<Segment> constraintSegs) {
    final coords = line.getCoordinates();
    for (int i = 1; i < coords.length; i++) {
      constraintSegs.add(Segment(coords[i - 1], coords[i]));
    }
  }

  QuadEdgeSubdivision getSubdivision() {
    create();
    return _subDiv!;
  }

  Geometry getEdges(GeometryFactory geomFact) {
    create();
    return _subDiv!.getEdges2(geomFact);
  }

  Geometry getTriangles(GeometryFactory geomFact) {
    create();
    return _subDiv!.getTriangles2(geomFact);
  }
}
