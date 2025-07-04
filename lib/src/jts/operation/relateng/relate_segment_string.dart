import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/noding/basic_segment_string.dart';

import 'node_section.dart';
import 'relate_geometry.dart';

class RelateSegmentString extends BasicSegmentString {
  static RelateSegmentString createLine(
      Array<Coordinate> pts, bool isA, int elementId, RelateGeometry parent) {
    return createSegmentString(pts, isA, Dimension.L, elementId, -1, null, parent);
  }

  static RelateSegmentString createRing(
    Array<Coordinate> pts,
    bool isA,
    int elementId,
    int ringId,
    Geometry poly,
    RelateGeometry parent,
  ) {
    return createSegmentString(pts, isA, Dimension.A, elementId, ringId, poly, parent);
  }

  static RelateSegmentString createSegmentString(
    Array<Coordinate> pts,
    bool isA,
    int dim,
    int elementId,
    int ringId,
    Geometry? poly,
    RelateGeometry parent,
  ) {
    pts = removeRepeatedPoints(pts);
    return RelateSegmentString(pts, isA, dim, elementId, ringId, poly, parent);
  }

  static Array<Coordinate> removeRepeatedPoints(Array<Coordinate> pts) {
    if (CoordinateArrays.hasRepeatedPoints(pts)) {
      pts = CoordinateArrays.removeRepeatedPoints(pts);
    }
    return pts;
  }

  bool isA;

  final int _dimension;
  final RelateGeometry _inputGeom;
  final Geometry? _parentPolygonal;

  int id;
  int ringId;

  RelateSegmentString(
    Array<Coordinate> pts,
    this.isA,
    this._dimension,
    this.id,
    this.ringId,
    this._parentPolygonal,
    this._inputGeom,
  ) : super(pts, null);

  RelateGeometry getGeometry() {
    return _inputGeom;
  }

  Geometry? getPolygonal() {
    return _parentPolygonal;
  }

  NodeSection createNodeSection(int segIndex, Coordinate intPt) {
    bool isNodeAtVertex =
        intPt.equals2D(getCoordinate(segIndex)) || intPt.equals2D(getCoordinate(segIndex + 1));
    Coordinate prev = prevVertex(segIndex, intPt)!;
    Coordinate next = nextVertex(segIndex, intPt)!;
    return NodeSection(
        isA, _dimension, id, ringId, _parentPolygonal, isNodeAtVertex, prev, intPt, next);
  }

  Coordinate? prevVertex(int segIndex, Coordinate pt) {
    Coordinate segStart = getCoordinate(segIndex);
    if (!segStart.equals2D(pt)) {
      return segStart;
    }

    if (segIndex > 0) {
      return getCoordinate(segIndex - 1);
    }

    if (isClosed()) {
      return prevInRing(segIndex);
    }

    return null;
  }

  Coordinate? nextVertex(int segIndex, Coordinate pt) {
    Coordinate segEnd = getCoordinate(segIndex + 1);
    if (!segEnd.equals2D(pt)) {
      return segEnd;
    }

    if (segIndex < (size() - 2)) {
      return getCoordinate(segIndex + 2);
    }

    if (isClosed()) {
      return nextInRing(segIndex + 1);
    }

    return null;
  }

  bool isContainingSegment(int segIndex, Coordinate pt) {
    if (pt.equals2D(getCoordinate(segIndex))) {
      return true;
    }

    if (pt.equals2D(getCoordinate(segIndex + 1))) {
      bool isFinalSegment = segIndex == (size() - 2);
      if (isClosed() || (!isFinalSegment)) {
        return false;
      }

      return true;
    }
    return true;
  }
}
