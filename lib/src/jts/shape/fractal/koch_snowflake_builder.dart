import 'dart:math';

import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/math/math.dart';
import 'package:dts/src/jts/shape/geometric_shape_builder.dart';

class KochSnowflakeBuilder extends GeometricShapeBuilder {
  final CoordinateList _coordList = CoordinateList();

  KochSnowflakeBuilder(super.geomFactory);

  static int recursionLevelForSize(int numPts) {
    double pow4 = numPts / 3;
    double exp = log(pow4) / log(4);
    return exp.toInt();
  }

  @override
  Geometry getGeometry() {
    int level = recursionLevelForSize(numPts);
    LineSegment baseLine = getSquareBaseLine();
    final pts = getBoundary(level, baseLine.getCoordinate(0), baseLine.getLength());
    return geomFactory.createPolygon(geomFactory.createLinearRings(pts), null);
  }

  static final double _kHeightFactor = sin(pi / 3.0);

  static const double _kOneThird = 1.0 / 3.0;

  static final double _kThirdHeight = _kHeightFactor / 3.0;

  static const double _kTwoThirds = 2.0 / 3.0;

  List<Coordinate> getBoundary(int level, Coordinate origin, double width) {
    double y = origin.y;
    if (level > 0) {
      y += _kThirdHeight * width;
    }
    Coordinate p0 = Coordinate(origin.x, y);
    Coordinate p1 = Coordinate(origin.x + (width / 2), y + (width * _kHeightFactor));
    Coordinate p2 = Coordinate(origin.x + width, y);
    addSide(level, p0, p1);
    addSide(level, p1, p2);
    addSide(level, p2, p0);
    _coordList.closeRing();
    return _coordList.toCoordinateList();
  }

  void addSide(int level, Coordinate p0, Coordinate p1) {
    if (level == 0) {
      addSegment(p0, p1);
    } else {
      Vector2D base = Vector2D.create3(p0, p1);
      Coordinate midPt = base.multiply(0.5).translate(p0);
      Vector2D heightVec = base.multiply(_kThirdHeight);
      Vector2D offsetVec = heightVec.rotateByQuarterCircle(1)!;
      Coordinate offsetPt = offsetVec.translate(midPt);
      int n2 = level - 1;
      Coordinate thirdPt = base.multiply(_kOneThird).translate(p0);
      Coordinate twoThirdPt = base.multiply(_kTwoThirds).translate(p0);
      addSide(n2, p0, thirdPt);
      addSide(n2, thirdPt, offsetPt);
      addSide(n2, offsetPt, twoThirdPt);
      addSide(n2, twoThirdPt, p1);
    }
  }

  void addSegment(Coordinate p0, Coordinate p1) {
    _coordList.add(p1);
  }
}
