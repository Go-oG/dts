import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/geom_filter.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/triangulate/tri/tri.dart';

import 'polygon_ear_clipper.dart';
import 'polygon_hole_joiner.dart';

class PolygonTriangulator {
  static Geometry triangulate(Geometry geom) {
    PolygonTriangulator triangulator = PolygonTriangulator(geom);
    return triangulator.getResult();
  }

  late final GeomFactory geomFact;

  final Geometry inputGeom;

  List<Tri>? triList;

  PolygonTriangulator(this.inputGeom) {
    geomFact = inputGeom.factory;
  }

  Geometry getResult() {
    compute();
    return Tri.toGeometry(triList!, geomFact);
  }

  List<Tri> getTriangles() {
    compute();
    return triList!;
  }

  void compute() {
    List<Polygon> polys = PolygonExtracter.getPolygons(inputGeom);
    triList = [];
    for (Polygon poly in polys) {
      if (poly.isEmpty()) continue;

      List<Tri> polyTriList = triangulatePolygon(poly);
      triList!.addAll(polyTriList);
    }
  }

  List<Tri> triangulatePolygon(Polygon poly) {
    final polyShell = PolygonHoleJoiner.join(poly);
    List<Tri> triList = PolygonEarClipper.triangulate(polyShell);
    return triList;
  }
}
