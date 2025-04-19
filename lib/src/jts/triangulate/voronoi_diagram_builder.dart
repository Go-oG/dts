import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/triangulate/quadedge/quad_edge_subdivision.dart';

import 'delaunay_triangulation_builder.dart';
import 'incremental_delaunay_triangulator.dart';

class VoronoiDiagramBuilder {
  late CoordinateList siteCoords;

  double tolerance = 0.0;

  QuadEdgeSubdivision? subdiv;

  Envelope? clipEnv;

  Envelope? _diagramEnv;

  void setSites2(Geometry geom) {
    siteCoords = DelaunayTriangulationBuilder.extractUniqueCoordinates(geom);
  }

  void setSites(List<Coordinate> coords) {
    siteCoords = DelaunayTriangulationBuilder.unique(CoordinateArrays.toCoordinateArray(coords));
  }

  void setClipEnvelope(Envelope clipEnv) {
    this.clipEnv = clipEnv;
  }

  void setTolerance(double tolerance) {
    this.tolerance = tolerance;
  }

  void create() {
    if (subdiv != null) return;

    _diagramEnv = clipEnv;
    if (_diagramEnv == null) {
      _diagramEnv = DelaunayTriangulationBuilder.envelope(siteCoords.rawList);
      double expandBy = _diagramEnv!.diameter;
      _diagramEnv!.expandBy(expandBy);
    }
    final vertices = DelaunayTriangulationBuilder.toVertices(siteCoords.rawList);
    subdiv = QuadEdgeSubdivision(_diagramEnv!, tolerance);
    final triangulator = IncrementalDelaunayTriangulator(subdiv!);
    triangulator.forceConvex(false);
    triangulator.insertSites(vertices);
  }

  QuadEdgeSubdivision getSubdivision() {
    create();
    return subdiv!;
  }

  Geometry getDiagram(GeometryFactory geomFact) {
    create();
    Geometry polys = subdiv!.getVoronoiDiagram(geomFact);
    return clipGeometryCollection(polys, _diagramEnv!);
  }

  static Geometry clipGeometryCollection(Geometry geom, Envelope clipEnv) {
    Geometry clipPoly = geom.factory.toGeometry(clipEnv);
    List<Geometry> clipped = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry g = geom.getGeometryN(i);
      Geometry? result;
      if (clipEnv.contains(g.getEnvelopeInternal())) {
        result = g;
      } else if (clipEnv.intersects(g.getEnvelopeInternal())) {
        result = clipPoly.intersection(g);
        result?.userData = g.userData;
      }
      if ((result != null) && (!result.isEmpty())) {
        clipped.add(result);
      }
    }
    return geom.factory.createGeometryCollection2(GeometryFactory.toGeometryArray(clipped)!);
  }
}
