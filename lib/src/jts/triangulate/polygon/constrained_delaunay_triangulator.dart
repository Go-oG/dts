import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/geometry_filter.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/triangulate/tri/tri.dart';
import 'package:dts/src/jts/triangulate/tri/triangulation_builder.dart';

import 'polygon_ear_clipper.dart';
import 'polygon_hole_joiner.dart';
import 'tri_delaunay_improver.dart';

class ConstrainedDelaunayTriangulator {
  static Geometry triangulate(Geometry geom) {
    ConstrainedDelaunayTriangulator cdt = ConstrainedDelaunayTriangulator(geom);
    return cdt.getResult();
  }

  late final GeometryFactory _geomFact;

  final Geometry inputGeom;

  List<Tri>? _triList;

  ConstrainedDelaunayTriangulator(this.inputGeom) {
    _geomFact = inputGeom.factory;
  }

  Geometry getResult() {
    compute();
    return Tri.toGeometry(_triList!, _geomFact);
  }

  List<Tri> getTriangles() {
    compute();
    return _triList!;
  }

  void compute() {
    if (_triList != null) return;

    List<Polygon> polys = PolygonExtracter.getPolygons(inputGeom);
    _triList = [];
    for (Polygon poly in polys) {
      List<Tri> polyTriList = triangulatePolygon(poly);
      _triList!.addAll(polyTriList);
    }
  }

  List<Tri> triangulatePolygon(Polygon poly) {
    Array<Coordinate> polyShell = PolygonHoleJoiner.join(poly);
    List<Tri> triList = PolygonEarClipper.triangulate(polyShell);
    TriangulationBuilder.build(triList);
    TriDelaunayImprover.improveS(triList);
    return triList;
  }
}
