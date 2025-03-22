import 'package:collection/collection.dart';
 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';

import '../../triangulate/tri/tri.dart';
import 'hull_tri.dart';
import 'hull_triangulation.dart';

class ConcaveHull {
  static double uniformGridEdgeLength(Geometry geom) {
    double areaCH = geom.convexHull().getArea();
    int numPts = geom.getNumPoints();
    return Math.sqrt(areaCH / numPts);
  }

  static Geometry concaveHullByLength(Geometry geom, double maxLength) {
    return concaveHullByLength2(geom, maxLength, false);
  }

  static Geometry concaveHullByLength2(Geometry geom, double maxLength, bool isHolesAllowed) {
    ConcaveHull hull = ConcaveHull(geom);
    hull.setMaximumEdgeLength(maxLength);
    hull.setHolesAllowed(isHolesAllowed);
    return hull.getHull();
  }

  static Geometry concaveHullByLengthRatio(Geometry geom, double lengthRatio) {
    return concaveHullByLengthRatio2(geom, lengthRatio, false);
  }

  static Geometry concaveHullByLengthRatio2(Geometry geom, double lengthRatio, bool isHolesAllowed) {
    ConcaveHull hull = ConcaveHull(geom);
    hull.setMaximumEdgeLengthRatio(lengthRatio);
    hull.setHolesAllowed(isHolesAllowed);
    return hull.getHull();
  }

  static Geometry alphaShape(Geometry geom, double alpha, bool isHolesAllowed) {
    ConcaveHull hull = ConcaveHull(geom);
    hull.setAlpha(alpha);
    hull.setHolesAllowed(isHolesAllowed);
    return hull.getHull();
  }

  static const int _paramEdgeLength = 1;

  static const int _paramAlpha = 2;

  final Geometry _inputGeometry;

  late final GeometryFactory _geomFactory;

  double _maxEdgeLengthRatio = -1;

  double _alpha = -1;

  bool _isHolesAllowed = false;

  int _criteriaType = _paramEdgeLength;

  double _maxSizeInHull = 0.0;

  ConcaveHull(this._inputGeometry) {
    _geomFactory = _inputGeometry.factory;
  }

  void setMaximumEdgeLength(double edgeLength) {
    if (edgeLength < 0) {
      throw IllegalArgumentException("Edge length must be non-negative");
    }

    _maxSizeInHull = edgeLength;
    _maxEdgeLengthRatio = -1;
    _criteriaType = _paramEdgeLength;
  }

  void setMaximumEdgeLengthRatio(double edgeLengthRatio) {
    if ((edgeLengthRatio < 0) || (edgeLengthRatio > 1)) {
      throw IllegalArgumentException("Edge length ratio must be in range [0,1]");
    }

    _maxEdgeLengthRatio = edgeLengthRatio;
    _criteriaType = _paramEdgeLength;
  }

  void setAlpha(double alpha) {
    _alpha = alpha;
    _maxSizeInHull = alpha;
    _criteriaType = _paramAlpha;
  }

  void setHolesAllowed(bool isHolesAllowed) {
    _isHolesAllowed = isHolesAllowed;
  }

  Geometry getHull() {
    if (_inputGeometry.isEmpty()) {
      return _geomFactory.createPolygon();
    }
    List<HullTri> triList = HullTriangulation.createDelaunayTriangulation(_inputGeometry);
    _setSize(triList);
    if (_maxEdgeLengthRatio >= 0) {
      _maxSizeInHull = _computeTargetEdgeLength(triList, _maxEdgeLengthRatio);
    }
    if (triList.isEmpty) {
      return _inputGeometry.convexHull();
    }

    _computeHull(triList);
    return _toGeometry(triList, _geomFactory);
  }

  void _setSize(List<HullTri> triList) {
    for (HullTri tri in triList) {
      if (_criteriaType == _paramEdgeLength) {
        tri.setSizeToLongestEdge();
      } else {
        tri.setSizeToCircumradius();
      }
    }
  }

  static double _computeTargetEdgeLength(List<HullTri> triList, double edgeLengthRatio) {
    if (edgeLengthRatio == 0) {
      return 0;
    }

    double maxEdgeLen = -1;
    double minEdgeLen = -1;
    for (HullTri tri in triList) {
      for (int i = 0; i < 3; i++) {
        double len = tri.getCoordinate(i).distance(tri.getCoordinate(Tri.next(i)));
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

  void _computeHull(List<HullTri> triList) {
    _computeHullBorder(triList);
    if (_isHolesAllowed) {
      _computeHullHoles(triList);
    }
  }

  void _computeHullBorder(List<HullTri> triList) {
    PriorityQueue<HullTri> queue = _createBorderQueue(triList);
    while (queue.isNotEmpty) {
      HullTri tri = queue.removeFirst();
      if (_isInHull(tri)) {
        break;
      }

      if (_isRemovableBorder(tri)) {
        HullTri? adj0 = tri.getAdjacent(0) as HullTri?;
        HullTri? adj1 = tri.getAdjacent(1) as HullTri?;
        HullTri? adj2 = tri.getAdjacent(2) as HullTri?;
        tri.remove(triList);
        _addBorderTri(adj0, queue);
        _addBorderTri(adj1, queue);
        _addBorderTri(adj2, queue);
      }
    }
  }

  PriorityQueue<HullTri> _createBorderQueue(List<HullTri> triList) {
    PriorityQueue<HullTri> queue = PriorityQueue<HullTri>();
    for (HullTri tri in triList) {
      _addBorderTri(tri, queue);
    }
    return queue;
  }

  void _addBorderTri(HullTri? tri, PriorityQueue<HullTri> queue) {
    if (tri == null) {
      return;
    }

    if (tri.numAdjacent() != 2) {
      return;
    }

    _setSize2(tri);
    queue.add(tri);
  }

  void _setSize2(HullTri tri) {
    if (_criteriaType == _paramEdgeLength) {
      tri.setSizeToBoundary();
    } else {
      tri.setSizeToCircumradius();
    }
  }

  bool _isInHull(HullTri tri) {
    return tri.getSize() < _maxSizeInHull;
  }

  void _computeHullHoles(List<HullTri> triList) {
    List<HullTri> candidateHoles = _findCandidateHoles(triList, _maxSizeInHull);
    for (HullTri tri in candidateHoles) {
      if ((tri.isRemoved() || tri.isBorder()) || tri.hasBoundaryTouch()) {
        continue;
      }

      _removeHole(triList, tri);
    }
  }

  static List<HullTri> _findCandidateHoles(List<HullTri> triList, double maxSizeInHull) {
    List<HullTri> candidates = [];
    for (HullTri tri in triList) {
      if (tri.getSize() < maxSizeInHull) {
        continue;
      }

      bool isTouchingBoundary = tri.isBorder() || tri.hasBoundaryTouch();
      if (!isTouchingBoundary) {
        candidates.add(tri);
      }
    }
    candidates.sort(null);
    return candidates;
  }

  void _removeHole(List<HullTri> triList, HullTri triHole) {
    PriorityQueue<HullTri> queue = PriorityQueue<HullTri>();
    queue.add(triHole);
    while (queue.isNotEmpty) {
      HullTri tri = queue.removeFirst();
      if ((tri != triHole) && _isInHull(tri)) {
        break;
      }

      if ((tri == triHole) || _isRemovableHole(tri)) {
        HullTri? adj0 = tri.getAdjacent(0) as HullTri?;
        HullTri? adj1 = tri.getAdjacent(1) as HullTri?;
        HullTri? adj2 = tri.getAdjacent(2) as HullTri?;
        tri.remove(triList);
        _addBorderTri(adj0, queue);
        _addBorderTri(adj1, queue);
        _addBorderTri(adj2, queue);
      }
    }
  }

  bool _isRemovableBorder(HullTri tri) {
    if (tri.numAdjacent() != 2) {
      return false;
    }

    return !tri.isConnecting();
  }

  bool _isRemovableHole(HullTri tri) {
    if (tri.numAdjacent() != 2) {
      return false;
    }

    return !tri.hasBoundaryTouch();
  }

  Geometry _toGeometry(List<HullTri> triList, GeometryFactory geomFactory) {
    if (!_isHolesAllowed) {
      return HullTriangulation.traceBoundaryPolygon(triList, geomFactory);
    }
    return HullTriangulation.union(triList, geomFactory);
  }
}
