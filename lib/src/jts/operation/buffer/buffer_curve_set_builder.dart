import 'package:dts/src/jts/algorithm/distance.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';
import 'package:dts/src/jts/geom/multi_point.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/triangle.dart';
import 'package:dts/src/jts/geomgraph/label.dart';
import 'package:dts/src/jts/noding/noded_segment_string.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'buffer_parameters.dart';
import 'offset_curve_builder.dart';

class BufferCurveSetBuilder {
  Geometry inputGeom;

  double distance = 0;

  late OffsetCurveBuilder _curveBuilder;

  final List<SegmentString> _curveList = [];

  bool isInvertOrientation = false;

  BufferCurveSetBuilder(this.inputGeom, this.distance, PrecisionModel precisionModel, BufferParameters bufParams) {
    _curveBuilder = OffsetCurveBuilder(precisionModel, bufParams);
  }

  void setInvertOrientation(bool isInvertOrientation) {
    this.isInvertOrientation = isInvertOrientation;
  }

  bool isRingCCW(List<Coordinate> coord) {
    bool isCCW = Orientation.isCCWArea(coord);
    if (isInvertOrientation) {
      return !isCCW;
    }

    return isCCW;
  }

  List<SegmentString> getCurves() {
    add(inputGeom);
    return _curveList;
  }

  void addCurve(List<Coordinate>? coord, int leftLoc, int rightLoc) {
    if ((coord == null) || (coord.length < 2)) {
      return;
    }

    SegmentString e = NodedSegmentString(coord, Label.of4(0, Location.boundary, leftLoc, rightLoc));
    _curveList.add(e);
  }

  void add(Geometry g) {
    if (g.isEmpty()) {
      return;
    }

    if (g is Polygon) {
      addPolygon(g);
      return;
    }
    if (g is LineString) {
      addLineString(g);
      return;
    }
    if (g is Point) {
      addPoint(g);
      return;
    }
    if (g is MultiPoint) {
      addCollection(g);
      return;
    }
    if (g is MultiLineString) {
      addCollection(g);
      return;
    }
    if (g is MultiPolygon) {
      addCollection(g);
      return;
    }
    if (g is GeometryCollection) {
      addCollection(g);
      return;
    }

    throw "UnsupportedOperationException ${g.runtimeType}";
  }

  void addCollection(GeometryCollection gc) {
    for (int i = 0; i < gc.getNumGeometries(); i++) {
      Geometry g = gc.getGeometryN(i);
      add(g);
    }
  }

  void addPoint(Point p) {
    if (distance <= 0.0) {
      return;
    }

    List<Coordinate> coord = p.getCoordinates();
    if (coord.isNotEmpty && !coord[0].isValid()) {
      return;
    }

    List<Coordinate> curve = _curveBuilder.getLineCurve(coord, distance)!;
    addCurve(curve, Location.exterior, Location.interior);
  }

  void addLineString(LineString line) {
    if (_curveBuilder.isLineOffsetEmpty(distance)) {
      return;
    }

    List<Coordinate> coord = clean(line.getCoordinates());
    if (CoordinateArrays.isRing(coord) && (!_curveBuilder.getBufferParameters().isSingleSided())) {
      addLinearRingSides(coord, distance);
    } else {
      List<Coordinate> curve = _curveBuilder.getLineCurve(coord, distance)!;
      addCurve(curve, Location.exterior, Location.interior);
    }
  }

  static List<Coordinate> clean(List<Coordinate> coords) {
    return CoordinateArrays.removeRepeatedOrInvalidPoints(coords);
  }

  void addPolygon(Polygon p) {
    double offsetDistance = distance;
    int offsetSide = Position.left;
    if (distance < 0.0) {
      offsetDistance = -distance;
      offsetSide = Position.right;
    }
    LinearRing shell = p.getExteriorRing();
    List<Coordinate> shellCoord = clean(shell.getCoordinates());
    if ((distance < 0.0) && isRingFullyEroded(shell, false, distance)) {
      return;
    }

    if ((distance <= 0.0) && (shellCoord.length < 3)) {
      return;
    }

    addPolygonRingSide(shellCoord, offsetDistance, offsetSide, Location.exterior, Location.interior);
    for (int i = 0; i < p.getNumInteriorRing(); i++) {
      LinearRing hole = p.getInteriorRingN(i);
      List<Coordinate> holeCoord = clean(hole.getCoordinates());
      if ((distance > 0.0) && isRingFullyEroded(hole, true, distance)) {
        continue;
      }

      addPolygonRingSide(
        holeCoord,
        offsetDistance,
        Position.opposite(offsetSide),
        Location.interior,
        Location.exterior,
      );
    }
  }

  void addPolygonRingSide(List<Coordinate> coord, double offsetDistance, int side, int cwLeftLoc, int cwRightLoc) {
    if ((offsetDistance == 0.0) && (coord.length < LinearRing.kMinValidSize)) {
      return;
    }

    int leftLoc = cwLeftLoc;
    int rightLoc = cwRightLoc;
    bool isCCW = isRingCCW(coord);
    if ((coord.length >= LinearRing.kMinValidSize) && isCCW) {
      leftLoc = cwRightLoc;
      rightLoc = cwLeftLoc;
      side = Position.opposite(side);
    }
    addRingSide(coord, offsetDistance, side, leftLoc, rightLoc);
  }

  void addLinearRingSides(List<Coordinate> coord, double distance) {
    bool isHoleComputed = !isRingFullyEroded2(coord, CoordinateArrays.envelope(coord), true, distance);
    bool isCCW = isRingCCW(coord);
    bool isShellLeft = !isCCW;
    if (isShellLeft || isHoleComputed) {
      addRingSide(coord, distance, Position.left, Location.exterior, Location.interior);
    }
    bool isShellRight = isCCW;
    if (isShellRight || isHoleComputed) {
      addRingSide(coord, distance, Position.right, Location.interior, Location.exterior);
    }
  }

  void addRingSide(List<Coordinate> coord, double offsetDistance, int side, int leftLoc, int rightLoc) {
    List<Coordinate> curve = _curveBuilder.getRingCurve(coord, side, offsetDistance)!;
    if (isRingCurveInverted(coord, offsetDistance, curve)) {
      return;
    }
    addCurve(curve, leftLoc, rightLoc);
  }

  static const int _maxInvertedRingSize = 9;

  static const int _invertedCurveVertexFactor = 4;

  static const double _nearnessFactor = 0.99;

  static bool isRingCurveInverted(List<Coordinate> inputRing, double distance, List<Coordinate> curveRing) {
    if (distance == 0.0) {
      return false;
    }

    if (inputRing.length <= 3) {
      return false;
    }

    if (inputRing.length >= _maxInvertedRingSize) {
      return false;
    }

    if (curveRing.length > (_invertedCurveVertexFactor * inputRing.length)) {
      return false;
    }

    if (hasPointOnBuffer(inputRing, distance, curveRing)) {
      return false;
    }

    return true;
  }

  static bool hasPointOnBuffer(List<Coordinate> inputRing, double distance, List<Coordinate> curveRing) {
    double distTol = _nearnessFactor * distance.abs();
    for (int i = 0; i < (curveRing.length - 1); i++) {
      Coordinate v = curveRing[i];
      double dist = Distance.pointToSegmentString(v, inputRing);
      if (dist > distTol) {
        return true;
      }
      int iNext = (i < (curveRing.length - 1)) ? i + 1 : 0;
      Coordinate vnext = curveRing[iNext];
      Coordinate midPt = LineSegment.midPoint2(v, vnext);
      double distMid = Distance.pointToSegmentString(midPt, inputRing);
      if (distMid > distTol) {
        return true;
      }
    }
    return false;
  }

  static bool isRingFullyEroded(LinearRing ring, bool isHole, double bufferDistance) {
    return isRingFullyEroded2(ring.getCoordinates(), ring.getEnvelopeInternal(), isHole, bufferDistance);
  }

  static bool isRingFullyEroded2(List<Coordinate> ringCoord, Envelope ringEnv, bool isHole, double bufferDistance) {
    if (ringCoord.length < 4) {
      return true;
    }

    if (ringCoord.length == 4) {
      return isTriangleErodedCompletely(ringCoord, bufferDistance);
    }

    bool isErodable = (isHole && (bufferDistance > 0)) || ((!isHole) && (bufferDistance < 0));
    if (isErodable) {
      double envMinDimension = ringEnv.shortSide;
      if (2 * bufferDistance.abs() > envMinDimension) {
        return true;
      }
    }
    return false;
  }

  static bool isTriangleErodedCompletely(List<Coordinate> triangleCoord, double bufferDistance) {
    Triangle tri = Triangle(triangleCoord[0], triangleCoord[1], triangleCoord[2]);
    Coordinate inCentre = tri.inCentre();
    double distToCentre = Distance.pointToSegment(inCentre, tri.p0, tri.p1);
    return distToCentre < bufferDistance.abs();
  }
}
