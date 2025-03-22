 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';
import 'package:dts/src/jts/geom/multi_point.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygonal.dart';
import 'package:dts/src/jts/geom/util/linear_component_extracter.dart';
import 'package:dts/src/jts/noding/basic_segment_string.dart';
import 'package:dts/src/jts/noding/mcindex_noder.dart';
import 'package:dts/src/jts/noding/segment_intersector.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

class IsSimpleOp {
  static bool isSimple2(Geometry geom) {
    IsSimpleOp op = IsSimpleOp(geom);
    return op.isSimple();
  }

  static Coordinate? getNonSimpleLocation2(Geometry geom) {
    IsSimpleOp op = IsSimpleOp(geom);
    return op.getNonSimpleLocation();
  }

  final Geometry inputGeom;

  late final bool _isClosedEndpointsInInterior;

  bool _isFindAllLocations = false;

  bool _isSimple = false;

  List<Coordinate>? _nonSimplePts;

  IsSimpleOp(this.inputGeom, [BoundaryNodeRule? boundaryNodeRule]) {
    boundaryNodeRule ??= BoundaryNodeRule.mod2BR;
    _isClosedEndpointsInInterior = !boundaryNodeRule.isInBoundary(2);
  }

  void setFindAllLocations(bool isFindAll) {
    _isFindAllLocations = isFindAll;
  }

  bool isSimple() {
    compute();
    return _isSimple;
  }

  Coordinate? getNonSimpleLocation() {
    compute();
    return _nonSimplePts?.firstOrNull;
  }

  List<Coordinate> getNonSimpleLocations() {
    compute();
    return _nonSimplePts!;
  }

  void compute() {
    if (_nonSimplePts != null) return;

    _nonSimplePts = [];
    _isSimple = computeSimple(inputGeom);
  }

  bool computeSimple(Geometry geom) {
    if (geom.isEmpty()) return true;

    if (geom is Point) return true;

    if (geom is LineString) return isSimpleLinearGeometry(geom);

    if (geom is MultiLineString) return isSimpleLinearGeometry(geom);

    if (geom is MultiPoint) return isSimpleMultiPoint(geom);

    if (geom is Polygonal) return isSimplePolygonal(geom);

    if (geom is GeometryCollection) return isSimpleGeometryCollection(geom);

    return true;
  }

  bool isSimpleMultiPoint(MultiPoint mp) {
    if (mp.isEmpty()) return true;

    bool isSimple = true;
    Set<Coordinate> points = <Coordinate>{};
    for (int i = 0; i < mp.getNumGeometries(); i++) {
      Point pt = mp.getGeometryN(i);
      Coordinate p = pt.getCoordinate()!;
      if (points.contains(p)) {
        _nonSimplePts!.add(p);
        isSimple = false;
        if (!_isFindAllLocations) break;
      } else {
        points.add(p);
      }
    }
    return isSimple;
  }

  bool isSimplePolygonal(Geometry geom) {
    bool isSimple = true;
    List<Geometry> rings = LinearComponentExtracter.getLines(geom);
    for (Geometry ring in rings) {
      if (!isSimpleLinearGeometry(ring)) {
        isSimple = false;
        if (!_isFindAllLocations) break;
      }
    }
    return isSimple;
  }

  bool isSimpleGeometryCollection(Geometry geom) {
    bool isSimple = true;
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry comp = geom.getGeometryN(i);
      if (!computeSimple(comp)) {
        isSimple = false;
        if (!_isFindAllLocations) break;
      }
    }
    return isSimple;
  }

  bool isSimpleLinearGeometry(Geometry geom) {
    if (geom.isEmpty()) return true;

    List<SegmentString> segStrings = extractSegmentStrings(geom);
    final segInt = _NonSimpleIntersectionFinder(_isClosedEndpointsInInterior, _isFindAllLocations, _nonSimplePts!);
    MCIndexNoder noder = MCIndexNoder();
    noder.setSegmentIntersector(segInt);
    noder.computeNodes(segStrings);
    if (segInt.hasIntersection()) {
      return false;
    }
    return true;
  }

  static List<SegmentString> extractSegmentStrings(Geometry geom) {
    List<SegmentString> segStrings = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      LineString line = geom.getGeometryN(i) as LineString;
      Array<Coordinate>? trimPts = trimRepeatedPoints(line.getCoordinates());
      if (trimPts != null) {
        SegmentString ss = BasicSegmentString(trimPts, null);
        segStrings.add(ss);
      }
    }
    return segStrings;
  }

  static Array<Coordinate>? trimRepeatedPoints(Array<Coordinate> pts) {
    if (pts.length <= 2) return pts;

    int len = pts.length;
    bool hasRepeatedStart = pts[0].equals2D(pts[1]);
    bool hasRepeatedEnd = pts[len - 1].equals2D(pts[len - 2]);
    if ((!hasRepeatedStart) && (!hasRepeatedEnd)) return pts;

    int startIndex = 0;
    Coordinate startPt = pts[0];
    while ((startIndex < (len - 1)) && startPt.equals2D(pts[startIndex + 1])) {
      startIndex++;
    }
    int endIndex = len - 1;
    Coordinate endPt = pts[endIndex];
    while ((endIndex > 0) && endPt.equals2D(pts[endIndex - 1])) {
      endIndex--;
    }
    if ((endIndex - startIndex) < 1) {
      return null;
    }
    Array<Coordinate> trimPts = CoordinateArrays.extract(pts, startIndex, endIndex);
    return trimPts;
  }
}

class _NonSimpleIntersectionFinder implements NSegmentIntersector {
  final bool isClosedEndpointsInInterior;

  final bool _isFindAll;

  LineIntersector li = RobustLineIntersector();

  final List<Coordinate> _intersectionPts;

  _NonSimpleIntersectionFinder(this.isClosedEndpointsInInterior, this._isFindAll, this._intersectionPts);

  bool hasIntersection() {
    return _intersectionPts.size > 0;
  }

  @override
  void processIntersections(SegmentString ss0, int segIndex0, SegmentString ss1, int segIndex1) {
    bool isSameSegString = ss0 == ss1;
    bool isSameSegment = isSameSegString && (segIndex0 == segIndex1);
    if (isSameSegment) return;

    bool hasInt = findIntersection(ss0, segIndex0, ss1, segIndex1);
    if (hasInt) {
      _intersectionPts.add(li.getIntersection(0));
    }
  }

  bool findIntersection(SegmentString ss0, int segIndex0, SegmentString ss1, int segIndex1) {
    Coordinate p00 = ss0.getCoordinate(segIndex0);
    Coordinate p01 = ss0.getCoordinate(segIndex0 + 1);
    Coordinate p10 = ss1.getCoordinate(segIndex1);
    Coordinate p11 = ss1.getCoordinate(segIndex1 + 1);
    li.computeIntersection2(p00, p01, p10, p11);
    if (!li.hasIntersection()) return false;

    bool hasInteriorInt = li.isInteriorIntersection();
    if (hasInteriorInt) return true;

    bool hasEqualSegments = li.getIntersectionNum() >= 2;
    if (hasEqualSegments) return true;

    bool isSameSegString = ss0 == ss1;
    bool isAdjacentSegment = isSameSegString && (Math.abs(segIndex1 - segIndex0) <= 1);
    if (isAdjacentSegment) return false;

    bool isIntersectionEndpt0 = isIntersectionEndpoint(ss0, segIndex0, li, 0);
    bool isIntersectionEndpt1 = isIntersectionEndpoint(ss1, segIndex1, li, 1);
    bool hasInteriorVertexInt = !(isIntersectionEndpt0 && isIntersectionEndpt1);
    if (hasInteriorVertexInt) return true;

    if (isClosedEndpointsInInterior && (!isSameSegString)) {
      bool hasInteriorEndpointInt = ss0.isClosed() || ss1.isClosed();
      if (hasInteriorEndpointInt) return true;
    }
    return false;
  }

  static bool isIntersectionEndpoint(SegmentString ss, int ssIndex, LineIntersector li, int liSegmentIndex) {
    int vertexIndex = intersectionVertexIndex(li, liSegmentIndex);
    if (vertexIndex == 0) {
      return ssIndex == 0;
    } else {
      return (ssIndex + 2) == ss.size();
    }
  }

  static int intersectionVertexIndex(LineIntersector li, int segmentIndex) {
    Coordinate intPt = li.getIntersection(0);
    Coordinate endPt0 = li.getEndpoint(segmentIndex, 0);
    return intPt.equals2D(endPt0) ? 0 : 1;
  }

  @override
  bool isDone() {
    if (_isFindAll) return false;
    return _intersectionPts.size > 0;
  }
}
