import 'package:d_util/d_util.dart';
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
    double exp = Math.log(pow4) / Math.log(4);
    return exp.toInt();
  }

  @override
  Geometry getGeometry() {
    int level = recursionLevelForSize(numPts);
    LineSegment baseLine = getSquareBaseLine();
    Array<Coordinate> pts = getBoundary(level, baseLine.getCoordinate(0), baseLine.getLength());
    return geomFactory.createPolygon(geomFactory.createLinearRings(pts), null);
  }

  static final double _HEIGHT_FACTOR = Math.sin(Math.pi / 3.0);

  static const double _ONE_THIRD = 1.0 / 3.0;

  static final double _THIRD_HEIGHT = _HEIGHT_FACTOR / 3.0;

  static const double _TWO_THIRDS = 2.0 / 3.0;

  Array<Coordinate> getBoundary(int level, Coordinate origin, double width) {
    double y = origin.y;
    if (level > 0) {
      y += _THIRD_HEIGHT * width;
    }
    Coordinate p0 = Coordinate(origin.x, y);
    Coordinate p1 = Coordinate(origin.x + (width / 2), y + (width * _HEIGHT_FACTOR));
    Coordinate p2 = Coordinate(origin.x + width, y);
    addSide(level, p0, p1);
    addSide(level, p1, p2);
    addSide(level, p2, p0);
    _coordList.closeRing();
    return _coordList.toCoordinateArray();
  }

  void addSide(int level, Coordinate p0, Coordinate p1) {
    if (level == 0) {
      addSegment(p0, p1);
    } else {
      Vector2D base = Vector2D.create3(p0, p1);
      Coordinate midPt = base.multiply(0.5).translate(p0);
      Vector2D heightVec = base.multiply(_THIRD_HEIGHT);
      Vector2D offsetVec = heightVec.rotateByQuarterCircle(1)!;
      Coordinate offsetPt = offsetVec.translate(midPt);
      int n2 = level - 1;
      Coordinate thirdPt = base.multiply(_ONE_THIRD).translate(p0);
      Coordinate twoThirdPt = base.multiply(_TWO_THIRDS).translate(p0);
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
