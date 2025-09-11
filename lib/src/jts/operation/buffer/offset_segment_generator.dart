import 'dart:math';

import 'package:dts/src/jts/algorithm/angle.dart';
import 'package:dts/src/jts/algorithm/distance.dart';
import 'package:dts/src/jts/algorithm/intersection.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/math/math.dart';

import 'buffer_parameters.dart';
import 'offset_segment_string.dart';

class OffsetSegmentGenerator {
  static const double _kOffsetSegmentSeparationFactor = 0.05;

  static const double _kInsideTurnVertexSnapDistanceFactor = 0.001;

  static const double _kCurveVertexSnapDistanceFactor = 1.0E-4;

  static const int _kMaxClosingSegLenFactor = 80;

  double _filletAngleQuantum = 0;

  int _closingSegLengthFactor = 1;

  late OffsetSegmentString _segList;

  double distance = 0.0;

  PrecisionModel precisionModel;

  BufferParameters bufParams;

  LineIntersector li = RobustLineIntersector();

  late Coordinate _s0;

  late Coordinate _s1;

  late Coordinate _s2;

  final LineSegment _seg0 = LineSegment.empty();

  final LineSegment _seg1 = LineSegment.empty();

  final LineSegment _offset0 = LineSegment.empty();

  final LineSegment _offset1 = LineSegment.empty();

  int _side = 0;

  bool _hasNarrowConcaveAngle = false;

  OffsetSegmentGenerator(this.precisionModel, this.bufParams, double distance) {
    int quadSegs = bufParams.getQuadrantSegments();
    if (quadSegs < 1) {
      quadSegs = 1;
    }
    _filletAngleQuantum = Angle.piOver2 / quadSegs;
    if ((bufParams.getQuadrantSegments() >= 8) && (bufParams.getJoinStyle() == BufferParameters.kJoinRound)) {
      _closingSegLengthFactor = _kMaxClosingSegLenFactor;
    }

    init(distance);
  }

  bool hasNarrowConcaveAngle() {
    return _hasNarrowConcaveAngle;
  }

  void init(double distance) {
    this.distance = distance.abs();
    _segList = OffsetSegmentString();
    _segList.setPrecisionModel(precisionModel);
    _segList.setMinimumVertexDistance(this.distance * _kCurveVertexSnapDistanceFactor);
  }

  void initSideSegments(Coordinate s1, Coordinate s2, int side) {
    _s1 = s1;
    _s2 = s2;
    _side = side;
    _seg1.setCoordinates2(s1, s2);
    computeOffsetSegment(_seg1, side, distance, _offset1);
  }

  List<Coordinate> getCoordinates() => _segList.getCoordinates();

  void closeRing() {
    _segList.closeRing();
  }

  void addSegments(List<Coordinate> pt, bool isForward) {
    _segList.addPts2(pt, isForward);
  }

  void addFirstSegment() {
    _segList.addPt(_offset1.p0);
  }

  void addLastSegment() {
    _segList.addPt(_offset1.p1);
  }

  void addNextSegment(Coordinate p, bool addStartPoint) {
    _s0 = _s1;
    _s1 = _s2;
    _s2 = p;
    _seg0.setCoordinates2(_s0, _s1);
    computeOffsetSegment(_seg0, _side, distance, _offset0);
    _seg1.setCoordinates2(_s1, _s2);
    computeOffsetSegment(_seg1, _side, distance, _offset1);
    if (_s1 == _s2) {
      return;
    }

    int orientation = Orientation.index(_s0, _s1, _s2);
    bool outsideTurn = ((orientation == Orientation.clockwise) && (_side == Position.left)) ||
        ((orientation == Orientation.counterClockwise) && (_side == Position.right));
    if (orientation == 0) {
      addCollinear(addStartPoint);
    } else if (outsideTurn) {
      addOutsideTurn(orientation, addStartPoint);
    } else {
      addInsideTurn(orientation, addStartPoint);
    }
  }

  void addCollinear(bool addStartPoint) {
    li.computeIntersection2(_s0, _s1, _s1, _s2);
    int numInt = li.getIntersectionNum();
    if (numInt >= 2) {
      if ((bufParams.getJoinStyle() == BufferParameters.kJoinBevel) ||
          (bufParams.getJoinStyle() == BufferParameters.kJoinMitre)) {
        if (addStartPoint) {
          _segList.addPt(_offset0.p1);
        }

        _segList.addPt(_offset1.p0);
      } else {
        addCornerFillet(_s1, _offset0.p1, _offset1.p0, Orientation.clockwise, distance);
      }
    }
  }

  void addOutsideTurn(int orientation, bool addStartPoint) {
    if (_offset0.p1.distance(_offset1.p0) < (distance * _kOffsetSegmentSeparationFactor)) {
      double segLen0 = _s0.distance(_s1);
      double segLen1 = _s1.distance(_s2);
      Coordinate offsetPt = (segLen0 > segLen1) ? _offset0.p1 : _offset1.p0;
      _segList.addPt(offsetPt);
      return;
    }
    if (bufParams.getJoinStyle() == BufferParameters.kJoinMitre) {
      addMitreJoin(_s1, _offset0, _offset1, distance);
    } else if (bufParams.getJoinStyle() == BufferParameters.kJoinBevel) {
      addBevelJoin(_offset0, _offset1);
    } else {
      if (addStartPoint) {
        _segList.addPt(_offset0.p1);
      }
      addCornerFillet(_s1, _offset0.p1, _offset1.p0, orientation, distance);
      _segList.addPt(_offset1.p0);
    }
  }

  void addInsideTurn(int orientation, bool addStartPoint) {
    li.computeIntersection2(_offset0.p0, _offset0.p1, _offset1.p0, _offset1.p1);
    if (li.hasIntersection()) {
      _segList.addPt(li.getIntersection(0));
    } else {
      _hasNarrowConcaveAngle = true;
      if (_offset0.p1.distance(_offset1.p0) < (distance * _kInsideTurnVertexSnapDistanceFactor)) {
        _segList.addPt(_offset0.p1);
      } else {
        _segList.addPt(_offset0.p1);
        if (_closingSegLengthFactor > 0) {
          Coordinate mid0 = Coordinate(
            ((_closingSegLengthFactor * _offset0.p1.x) + _s1.x) / (_closingSegLengthFactor + 1),
            ((_closingSegLengthFactor * _offset0.p1.y) + _s1.y) / (_closingSegLengthFactor + 1),
          );
          _segList.addPt(mid0);
          Coordinate mid1 = Coordinate(
            ((_closingSegLengthFactor * _offset1.p0.x) + _s1.x) / (_closingSegLengthFactor + 1),
            ((_closingSegLengthFactor * _offset1.p0.y) + _s1.y) / (_closingSegLengthFactor + 1),
          );
          _segList.addPt(mid1);
        } else {
          _segList.addPt(_s1);
        }
        _segList.addPt(_offset1.p0);
      }
    }
  }

  static void computeOffsetSegment(LineSegment seg, int side, double distance, LineSegment offset) {
    int sideSign = (side == Position.left) ? 1 : -1;
    double dx = seg.p1.x - seg.p0.x;
    double dy = seg.p1.y - seg.p0.y;
    double len = MathUtil.hypot(dx, dy);
    double ux = ((sideSign * distance) * dx) / len;
    double uy = ((sideSign * distance) * dy) / len;
    offset.p0.x = seg.p0.x - uy;
    offset.p0.y = seg.p0.y + ux;
    offset.p1.x = seg.p1.x - uy;
    offset.p1.y = seg.p1.y + ux;
  }

  void addLineEndCap(Coordinate p0, Coordinate p1) {
    LineSegment seg = LineSegment(p0, p1);
    LineSegment offsetL = LineSegment.empty();
    computeOffsetSegment(seg, Position.left, distance, offsetL);
    LineSegment offsetR = LineSegment.empty();
    computeOffsetSegment(seg, Position.right, distance, offsetR);
    double dx = p1.x - p0.x;
    double dy = p1.y - p0.y;
    double angle = atan2(dy, dx);
    switch (bufParams.getEndCapStyle()) {
      case BufferParameters.kCapRound:
        _segList.addPt(offsetL.p1);
        addDirectedFillet(p1, angle + Angle.piOver2, angle - Angle.piOver2, Orientation.clockwise, distance);
        _segList.addPt(offsetR.p1);
        break;
      case BufferParameters.kCapFlat:
        _segList.addPt(offsetL.p1);
        _segList.addPt(offsetR.p1);
        break;
      case BufferParameters.kCapSquare:
        Coordinate squareCapSideOffset = Coordinate();
        squareCapSideOffset.x = distance.abs() * Angle.cosSnap(angle);
        squareCapSideOffset.y = distance.abs() * Angle.sinSnap(angle);
        Coordinate squareCapLOffset = Coordinate(
          offsetL.p1.x + squareCapSideOffset.x,
          offsetL.p1.y + squareCapSideOffset.y,
        );
        Coordinate squareCapROffset = Coordinate(
          offsetR.p1.x + squareCapSideOffset.x,
          offsetR.p1.y + squareCapSideOffset.y,
        );
        _segList.addPt(squareCapLOffset);
        _segList.addPt(squareCapROffset);
        break;
    }
  }

  void addMitreJoin(Coordinate cornerPt, LineSegment offset0, LineSegment offset1, double distance) {
    double mitreLimitDistance = bufParams.getMitreLimit() * distance;
    Coordinate? intPt = Intersection.intersection(offset0.p0, offset0.p1, offset1.p0, offset1.p1);
    if ((intPt != null) && (intPt.distance(cornerPt) <= mitreLimitDistance)) {
      _segList.addPt(intPt);
      return;
    }
    double bevelDist = Distance.pointToSegment(cornerPt, offset0.p1, offset1.p0);
    if (bevelDist >= mitreLimitDistance) {
      addBevelJoin(offset0, offset1);
      return;
    }
    addLimitedMitreJoin(offset0, offset1, distance, mitreLimitDistance);
  }

  void addLimitedMitreJoin(LineSegment offset0, LineSegment offset1, double distance, double mitreLimitDistance) {
    Coordinate cornerPt = _seg0.p1;
    double angInterior = Angle.angleBetweenOriented(_seg0.p0, cornerPt, _seg1.p1);
    double angInterior2 = angInterior / 2;
    double dir0 = Angle.angle2(cornerPt, _seg0.p0);
    double dirBisector = Angle.normalize(dir0 + angInterior2);
    Coordinate bevelMidPt = project(cornerPt, -mitreLimitDistance, dirBisector);
    double dirBevel = Angle.normalize(dirBisector + Angle.piOver2);
    Coordinate bevel0 = project(bevelMidPt, distance, dirBevel);
    Coordinate bevel1 = project(bevelMidPt, distance, dirBevel + pi);
    Coordinate? bevelInt0 = Intersection.lineSegment(offset0.p0, offset0.p1, bevel0, bevel1);
    Coordinate? bevelInt1 = Intersection.lineSegment(offset1.p0, offset1.p1, bevel0, bevel1);
    if ((bevelInt0 != null) && (bevelInt1 != null)) {
      _segList.addPt(bevelInt0);
      _segList.addPt(bevelInt1);
      return;
    }
    addBevelJoin(offset0, offset1);
  }

  static Coordinate project(Coordinate pt, double d, double dir) {
    double x = pt.x + (d * Angle.cosSnap(dir));
    double y = pt.y + (d * Angle.sinSnap(dir));
    return Coordinate(x, y);
  }

  void addBevelJoin(LineSegment offset0, LineSegment offset1) {
    _segList.addPt(offset0.p1);
    _segList.addPt(offset1.p0);
  }

  void addCornerFillet(Coordinate p, Coordinate p0, Coordinate p1, int direction, double radius) {
    double dx0 = p0.x - p.x;
    double dy0 = p0.y - p.y;
    double startAngle = atan2(dy0, dx0);
    double dx1 = p1.x - p.x;
    double dy1 = p1.y - p.y;
    double endAngle = atan2(dy1, dx1);
    if (direction == Orientation.clockwise) {
      if (startAngle <= endAngle) {
        startAngle += Angle.piTimes2;
      }
    } else if (startAngle >= endAngle) {
      startAngle -= Angle.piTimes2;
    }

    _segList.addPt(p0);
    addDirectedFillet(p, startAngle, endAngle, direction, radius);
    _segList.addPt(p1);
  }

  void addDirectedFillet(Coordinate p, double startAngle, double endAngle, int direction, double radius) {
    int directionFactor = (direction == Orientation.clockwise) ? -1 : 1;
    double totalAngle = (startAngle - endAngle).abs();
    int nSegs = ((totalAngle / _filletAngleQuantum) + 0.5).toInt();
    if (nSegs < 1) {
      return;
    }

    double angleInc = totalAngle / nSegs;
    Coordinate pt = Coordinate();
    for (int i = 0; i < nSegs; i++) {
      double angle = startAngle + ((directionFactor * i) * angleInc);
      pt.x = p.x + (radius * Angle.cosSnap(angle));
      pt.y = p.y + (radius * Angle.sinSnap(angle));
      _segList.addPt(pt);
    }
  }

  void createCircle(Coordinate p) {
    Coordinate pt = Coordinate(p.x + distance, p.y);
    _segList.addPt(pt);
    addDirectedFillet(p, 0.0, Angle.piTimes2, -1, distance);
    _segList.closeRing();
  }

  void createSquare(Coordinate p) {
    _segList.addPt(Coordinate(p.x + distance, p.y + distance));
    _segList.addPt(Coordinate(p.x + distance, p.y - distance));
    _segList.addPt(Coordinate(p.x - distance, p.y - distance));
    _segList.addPt(Coordinate(p.x - distance, p.y + distance));
    _segList.closeRing();
  }
}
