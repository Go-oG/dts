import 'dart:collection';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/operation/overlayng/coverage_union.dart';
import 'package:dts/src/jts/triangulate/polygon/constrained_delaunay_triangulator.dart';
import 'package:dts/src/jts/triangulate/tri/tri.dart';

import 'outer_shells_extracter.dart';

class ConcaveHullOfPolygons {
  static Geometry concaveHullByLength(Geometry polygons, double maxLength) {
    return concaveHullByLength2(polygons, maxLength, false, false);
  }

  static Geometry concaveHullByLength2(
      Geometry polygons, double maxLength, bool isTight, bool isHolesAllowed) {
    ConcaveHullOfPolygons hull = ConcaveHullOfPolygons(polygons);
    hull.setMaximumEdgeLength(maxLength);
    hull.setHolesAllowed(isHolesAllowed);
    hull.setTight(isTight);
    return hull.getHull();
  }

  static Geometry concaveHullByLengthRatio(Geometry polygons, double lengthRatio) {
    return concaveHullByLengthRatio2(polygons, lengthRatio, false, false);
  }

  static Geometry concaveHullByLengthRatio2(
      Geometry polygons, double lengthRatio, bool isTight, bool isHolesAllowed) {
    ConcaveHullOfPolygons hull = ConcaveHullOfPolygons(polygons);
    hull.setMaximumEdgeLengthRatio(lengthRatio);
    hull.setHolesAllowed(isHolesAllowed);
    hull.setTight(isTight);
    return hull.getHull();
  }

  static Geometry concaveFillByLength(Geometry polygons, double maxLength) {
    ConcaveHullOfPolygons hull = ConcaveHullOfPolygons(polygons);
    hull.setMaximumEdgeLength(maxLength);
    return hull.getFill();
  }

  static Geometry concaveFillByLengthRatio(Geometry polygons, double lengthRatio) {
    ConcaveHullOfPolygons hull = ConcaveHullOfPolygons(polygons);
    hull.setMaximumEdgeLengthRatio(lengthRatio);
    return hull.getFill();
  }

  static const int _frameExpandFactor = 4;

  static const int _notSpecified = -1;

  static const int _notFound = -1;

  late final Geometry _inputPolygons;
  late final GeometryFactory geomFactory;
  double _maxEdgeLength = 0.0;

  double _maxEdgeLengthRatio = _notSpecified.toDouble();

  bool isHolesAllowed = false;

  bool _isTight = false;

  Array<LinearRing>? _polygonRings;

  late Set<Tri> _hullTris;

  late Queue<Tri> _borderTriQue;

  final Map<Tri, int> _borderEdgeMap = {};

  ConcaveHullOfPolygons(Geometry polygons) {
    if (!((polygons is Polygon) || (polygons is MultiPolygon))) {
      throw IllegalArgumentException("Input must be polygonal");
    }
    _inputPolygons = polygons;
    geomFactory = _inputPolygons.factory;
  }

  void setMaximumEdgeLength(double edgeLength) {
    if (edgeLength < 0) {
      throw IllegalArgumentException("Edge length must be non-negative");
    }

    _maxEdgeLength = edgeLength;
    _maxEdgeLengthRatio = _notSpecified.toDouble();
  }

  void setMaximumEdgeLengthRatio(double edgeLengthRatio) {
    if ((edgeLengthRatio < 0) || (edgeLengthRatio > 1)) {
      throw IllegalArgumentException("Edge length ratio must be in range [0,1]");
    }

    _maxEdgeLengthRatio = edgeLengthRatio;
  }

  void setHolesAllowed(bool isHolesAllowed) {
    this.isHolesAllowed = isHolesAllowed;
  }

  void setTight(bool isTight) {
    _isTight = isTight;
  }

  Geometry getHull() {
    if (_inputPolygons.isEmpty()) {
      return _createEmptyHull();
    }
    _buildHullTris();
    return _createHullGeometry(_hullTris, true);
  }

  Geometry getFill() {
    _isTight = true;
    if (_inputPolygons.isEmpty()) {
      return _createEmptyHull();
    }
    _buildHullTris();
    return _createHullGeometry(_hullTris, false);
  }

  Geometry _createEmptyHull() {
    return geomFactory.createPolygon();
  }

  void _buildHullTris() {
    _polygonRings = OuterShellsExtracter.extractShells(_inputPolygons);
    Polygon frame = _createFrame(_inputPolygons.getEnvelopeInternal(), _polygonRings, geomFactory);
    ConstrainedDelaunayTriangulator cdt = ConstrainedDelaunayTriangulator(frame);
    List<Tri> tris = cdt.getTriangles();
    Array<Coordinate> framePts = frame.getExteriorRing().getCoordinates();
    if (_maxEdgeLengthRatio >= 0) {
      _maxEdgeLength = _computeTargetEdgeLength(tris, framePts, _maxEdgeLengthRatio);
    }
    _hullTris = _removeFrameCornerTris(tris, framePts);
    _removeBorderTris();
    if (isHolesAllowed) {
      _removeHoleTris();
    }
  }

  static double _computeTargetEdgeLength(
      List<Tri> triList, Array<Coordinate> frameCorners, double edgeLengthRatio) {
    if (edgeLengthRatio == 0) {
      return 0;
    }

    double maxEdgeLen = -1;
    double minEdgeLen = -1;
    for (Tri tri in triList) {
      if (_isFrameTri(tri, frameCorners)) {
        continue;
      }

      for (int i = 0; i < 3; i++) {
        if (!tri.hasAdjacent2(i)) {
          continue;
        }

        double len = tri.getLength(i);
        if (len > maxEdgeLen) {
          maxEdgeLen = len;
        }

        if ((minEdgeLen < 0) || (len < minEdgeLen)) {
          minEdgeLen = len;
        }
      }
    }
    if (edgeLengthRatio == 1) {
      return 2 * maxEdgeLen;
    }

    return (edgeLengthRatio * (maxEdgeLen - minEdgeLen)) + minEdgeLen;
  }

  static Polygon _createFrame(
      Envelope polygonsEnv, Array<LinearRing>? polygonRings, GeometryFactory geomFactory) {
    double diam = polygonsEnv.diameter;
    Envelope envFrame = polygonsEnv.copy();
    envFrame.expandBy(_frameExpandFactor * diam);
    Polygon frameOuter = ((geomFactory.toGeometry(envFrame) as Polygon));
    LinearRing shell = ((frameOuter.getExteriorRing().copy() as LinearRing));
    return geomFactory.createPolygon(shell, polygonRings);
  }

  static bool _isFrameTri(Tri tri, Array<Coordinate> frameCorners) {
    int index = _vertexIndex(tri, frameCorners);
    bool isFrameTri = index >= 0;
    return isFrameTri;
  }

  Set<Tri> _removeFrameCornerTris(List<Tri> tris, Array<Coordinate> frameCorners) {
    Set<Tri> hullTris = HashSet<Tri>();
    _borderTriQue = Queue();
    for (Tri tri in tris) {
      int index = _vertexIndex(tri, frameCorners);
      bool isFrameTri = index != _notFound;
      if (isFrameTri) {
        int oppIndex = Tri.oppEdge(index);
        Tri? oppTri = tri.getAdjacent(oppIndex);
        bool isBorderTri = (oppTri != null) && (!_isFrameTri(oppTri, frameCorners));
        if (isBorderTri) {
          _addBorderTri(tri, oppIndex);
        }
        tri.remove2();
      } else {
        hullTris.add(tri);
      }
    }
    return hullTris;
  }

  static int _vertexIndex(Tri tri, Array<Coordinate> pts) {
    for (Coordinate p in pts) {
      int index = tri.getIndex(p);
      if (index >= 0) {
        return index;
      }
    }
    return _notFound;
  }

  void _removeBorderTris() {
    while (_borderTriQue.isNotEmpty) {
      Tri tri = _borderTriQue.removeFirst();
      if (!_hullTris.contains(tri)) {
        continue;
      }
      if (_isRemovable(tri)) {
        _addBorderTris(tri);
        _removeBorderTri(tri);
      }
    }
  }

  void _removeHoleTris() {
    while (true) {
      Tri holeTri = _findHoleSeedTri(_hullTris)!;
      _addBorderTris(holeTri);
      _removeBorderTri(holeTri);
      _removeBorderTris();
    }
  }

  Tri? _findHoleSeedTri(Set<Tri> tris) {
    for (Tri tri in tris) {
      if (_isHoleSeedTri(tri)) {
        return tri;
      }
    }
    return null;
  }

  bool _isHoleSeedTri(Tri tri) {
    if (_isBorderTri(tri)) {
      return false;
    }

    for (int i = 0; i < 3; i++) {
      if (tri.hasAdjacent2(i) && (tri.getLength(i) > _maxEdgeLength)) {
        return true;
      }
    }
    return false;
  }

  bool _isBorderTri(Tri tri) {
    for (int i = 0; i < 3; i++) {
      if (!tri.hasAdjacent2(i)) {
        return true;
      }
    }
    return false;
  }

  bool _isRemovable(Tri tri) {
    if (_isTight && _isTouchingSinglePolygon(tri)) {
      return true;
    }

    if (_borderEdgeMap.containsKey(tri)) {
      int borderEdgeIndex = _borderEdgeMap.get(tri)!;
      double edgeLen = tri.getLength(borderEdgeIndex);
      if (edgeLen > _maxEdgeLength) {
        return true;
      }
    }
    return false;
  }

  bool _isTouchingSinglePolygon(Tri tri) {
    Envelope envTri = _envelope(tri);
    for (LinearRing ring in _polygonRings!) {
      if (ring.getEnvelopeInternal().intersects(envTri)) {
        if (_hasAllVertices(ring, tri)) {
          return true;
        }
      }
    }
    return false;
  }

  void _addBorderTris(Tri tri) {
    _addBorderTri(tri, 0);
    _addBorderTri(tri, 1);
    _addBorderTri(tri, 2);
  }

  void _addBorderTri(Tri tri, int index) {
    Tri adj = tri.getAdjacent(index)!;
    _borderTriQue.add(adj);
    int borderEdgeIndex = adj.getIndex2(tri);
    _borderEdgeMap.put(adj, borderEdgeIndex);
  }

  void _removeBorderTri(Tri tri) {
    tri.remove2();
    _hullTris.remove(tri);
    _borderEdgeMap.remove(tri);
  }

  static bool _hasAllVertices(LinearRing ring, Tri tri) {
    for (int i = 0; i < 3; i++) {
      Coordinate v = tri.getCoordinate(i);
      if (!_hasVertex(ring, v)) {
        return false;
      }
    }
    return true;
  }

  static bool _hasVertex(LinearRing ring, Coordinate v) {
    for (int i = 1; i < ring.getNumPoints(); i++) {
      if (v.equals2D(ring.getCoordinateN(i))) {
        return true;
      }
    }
    return false;
  }

  static Envelope _envelope(Tri tri) {
    Envelope env = Envelope.of(tri.getCoordinate(0), tri.getCoordinate(1));
    env.expandToIncludeCoordinate(tri.getCoordinate(2));
    return env;
  }

  Geometry _createHullGeometry(Set<Tri> hullTris, bool isIncludeInput) {
    if ((!isIncludeInput) && hullTris.isEmpty) {
      return _createEmptyHull();
    }

    Geometry triCoverage = Tri.toGeometry(hullTris.toList(), geomFactory);
    Geometry fillGeometry = CoverageUnionNG.union(triCoverage);
    if (!isIncludeInput) {
      return fillGeometry;
    }
    if (fillGeometry.isEmpty()) {
      return _inputPolygons.copy();
    }
    Array<Geometry> geoms = [fillGeometry, _inputPolygons].toArray();
    GeometryCollection geomColl = geomFactory.createGeomCollection(geoms);
    Geometry hull = CoverageUnionNG.union(geomColl);
    return hull;
  }
}
