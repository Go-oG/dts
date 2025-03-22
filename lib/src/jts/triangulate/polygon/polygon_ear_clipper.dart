 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/angle.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/triangle.dart';
import 'package:dts/src/jts/index/rtree/vertex_sequence_packed_rtree.dart';
import 'package:dts/src/jts/triangulate/tri/tri.dart';

class PolygonEarClipper {
  static const int _NO_VERTEX_INDEX = -1;

  static List<Tri> triangulate(Array<Coordinate> polyShell) {
    PolygonEarClipper clipper = PolygonEarClipper(polyShell);
    return clipper.compute();
  }

  bool _isFlatCornersSkipped = false;

  final Array<Coordinate> _vertex;

  late final Array<int> _vertexNext;

  late int _vertexSize;

  late int _vertexFirst;

  late VertexSequencePackedRtree _vertexCoordIndex;

  late Array<int> _cornerIndex;

  PolygonEarClipper(this._vertex) {
    _vertexSize = _vertex.length - 1;
    _vertexNext = createNextLinks(_vertexSize);
    _vertexFirst = 0;
    _vertexCoordIndex = VertexSequencePackedRtree(_vertex);
  }

  static Array<int> createNextLinks(int size) {
    Array<int> next = Array(size);
    for (int i = 0; i < size; i++) {
      next[i] = i + 1;
    }
    next[size - 1] = 0;
    return next;
  }

  void setSkipFlatCorners(bool isFlatCornersSkipped) {
    _isFlatCornersSkipped = isFlatCornersSkipped;
  }

  List<Tri> compute() {
    List<Tri> triList = [];
    int cornerScanCount = 0;
    initCornerIndex();
    Array<Coordinate> corner = Array(3);
    fetchCorner(corner);
    while (true) {
      if (!isConvex(corner)) {
        bool isCornerRemoved = isCornerInvalid(corner) || (_isFlatCornersSkipped && isFlat(corner));
        if (isCornerRemoved) {
          removeCorner();
        }
        cornerScanCount++;
        if (cornerScanCount > (2 * _vertexSize)) {
          throw ("Unable to find a convex corner");
        }
      } else if (isValidEar(_cornerIndex[1], corner)) {
        triList.add(Tri.create(corner));
        removeCorner();
        cornerScanCount = 0;
      }
      if (cornerScanCount > (2 * _vertexSize)) {
        throw ("Unable to find a valid ear");
      }
      if (_vertexSize < 3) {
        return triList;
      }
      nextCorner(corner);
    }
  }

  bool isValidEar(int cornerIndex, Array<Coordinate> corner) {
    int intApexIndex = findIntersectingVertex(cornerIndex, corner);
    if (intApexIndex == _NO_VERTEX_INDEX) return true;

    if (_vertex[intApexIndex].equals2D(corner[1])) {
      return isValidEarScan(cornerIndex, corner);
    }
    return false;
  }

  int findIntersectingVertex(int cornerIndex, Array<Coordinate> corner) {
    Envelope cornerEnv = envelope(corner);
    Array<int> result = _vertexCoordIndex.query(cornerEnv);
    int dupApexIndex = _NO_VERTEX_INDEX;
    for (int i = 0; i < result.length; i++) {
      int vertIndex = result[i];
      if (((vertIndex == cornerIndex) || (vertIndex == (_vertex.length - 1))) || isRemoved(vertIndex)) continue;

      Coordinate v = _vertex[vertIndex];
      if (v.equals2D(corner[1])) {
        dupApexIndex = vertIndex;
      } else if (v.equals2D(corner[0]) || v.equals2D(corner[2])) {
        continue;
      } else if (Triangle.intersects(corner[0], corner[1], corner[2], v))
        return vertIndex;
    }
    if (dupApexIndex != _NO_VERTEX_INDEX) {
      return dupApexIndex;
    }
    return _NO_VERTEX_INDEX;
  }

  bool isValidEarScan(int cornerIndex, Array<Coordinate> corner) {
    double cornerAngle = Angle.angleBetweenOriented(corner[0], corner[1], corner[2]);
    int currIndex = nextIndex(_vertexFirst);
    int prevIndex = _vertexFirst;
    Coordinate vPrev = _vertex[prevIndex];
    for (int i = 0; i < _vertexSize; i++) {
      Coordinate v = _vertex[currIndex];
      if ((currIndex != cornerIndex) && v.equals2D(corner[1])) {
        Coordinate vNext = _vertex[nextIndex(currIndex)];
        double aOut = Angle.angleBetweenOriented(corner[0], corner[1], vNext);
        double aIn = Angle.angleBetweenOriented(corner[0], corner[1], vPrev);
        if ((aOut > 0) && (aOut < cornerAngle)) {
          return false;
        }
        if ((aIn > 0) && (aIn < cornerAngle)) {
          return false;
        }
        if ((aOut == 0) && (aIn == cornerAngle)) {
          return false;
        }
      }
      vPrev = v;
      prevIndex = currIndex;
      currIndex = nextIndex(currIndex);
    }
    return true;
  }

  static Envelope envelope(Array<Coordinate> corner) {
    Envelope cornerEnv = Envelope.of3(corner[0], corner[1]);
    cornerEnv.expandToInclude(corner[2]);
    return cornerEnv;
  }

  void removeCorner() {
    int cornerApexIndex = _cornerIndex[1];
    if (_vertexFirst == cornerApexIndex) {
      _vertexFirst = _vertexNext[cornerApexIndex];
    }
    _vertexNext[_cornerIndex[0]] = _vertexNext[cornerApexIndex];
    _vertexCoordIndex.remove(cornerApexIndex);
    _vertexNext[cornerApexIndex] = _NO_VERTEX_INDEX;
    _vertexSize--;
    _cornerIndex[1] = nextIndex(_cornerIndex[0]);
    _cornerIndex[2] = nextIndex(_cornerIndex[1]);
  }

  bool isRemoved(int vertexIndex) {
    return _NO_VERTEX_INDEX == _vertexNext[vertexIndex];
  }

  void initCornerIndex() {
    _cornerIndex = Array(3);
    _cornerIndex[0] = 0;
    _cornerIndex[1] = 1;
    _cornerIndex[2] = 2;
  }

  void fetchCorner(Array<Coordinate> cornerVertex) {
    cornerVertex[0] = _vertex[_cornerIndex[0]];
    cornerVertex[1] = _vertex[_cornerIndex[1]];
    cornerVertex[2] = _vertex[_cornerIndex[2]];
  }

  void nextCorner(Array<Coordinate> cornerVertex) {
    if (_vertexSize < 3) {
      return;
    }
    _cornerIndex[0] = nextIndex(_cornerIndex[0]);
    _cornerIndex[1] = nextIndex(_cornerIndex[0]);
    _cornerIndex[2] = nextIndex(_cornerIndex[1]);
    fetchCorner(cornerVertex);
  }

  int nextIndex(int index) {
    return _vertexNext[index];
  }

  static bool isConvex(Array<Coordinate> pts) {
    return Orientation.clockwise == Orientation.index(pts[0], pts[1], pts[2]);
  }

  static bool isFlat(Array<Coordinate> pts) {
    return Orientation.collinear == Orientation.index(pts[0], pts[1], pts[2]);
  }

  static bool isCornerInvalid(Array<Coordinate> pts) {
    return (pts[1].equals2D(pts[0]) || pts[1].equals2D(pts[2])) || pts[0].equals2D(pts[2]);
  }

  Polygon toGeometry() {
    GeometryFactory fact = GeometryFactory.empty();
    CoordinateList coordList = CoordinateList();
    int index = _vertexFirst;
    for (int i = 0; i < _vertexSize; i++) {
      Coordinate v = _vertex[index];
      index = nextIndex(index);
      coordList.add3(v, true);
    }
    coordList.closeRing();
    return fact.createPolygon(fact.createLinearRing2(coordList.toCoordinateArray()));
  }
}
