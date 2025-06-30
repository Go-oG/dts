import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/util/linear_component_extracter.dart';
import 'package:dts/src/jts/math/math.dart';

class OffsetPointGenerator {
  Geometry g;

  bool _doLeft = true;

  bool _doRight = true;

  OffsetPointGenerator(this.g);

  void setSidesToGenerate(bool doLeft, bool doRight) {
    _doLeft = doLeft;
    _doRight = doRight;
  }

  List<Coordinate> getPoints(double offsetDistance) {
    List<Coordinate> offsetPts = [];
    final lines = LinearComponentExtracter.getLines(g);
    for (var i in lines) {
      extractPoints(i, offsetDistance, offsetPts);
    }
    return offsetPts;
  }

  void extractPoints(LineString line, double offsetDistance, List<Coordinate> offsetPts) {
    Array<Coordinate> pts = line.getCoordinates();
    for (int i = 0; i < (pts.length - 1); i++) {
      computeOffsetPoints(pts[i], pts[i + 1], offsetDistance, offsetPts);
    }
  }

  void computeOffsetPoints(
      Coordinate p0, Coordinate p1, double offsetDistance, List<Coordinate> offsetPts) {
    double dx = p1.x - p0.x;
    double dy = p1.y - p0.y;
    double len = MathUtil.hypot(dx, dy);
    double ux = (offsetDistance * dx) / len;
    double uy = (offsetDistance * dy) / len;
    double midX = (p1.x + p0.x) / 2;
    double midY = (p1.y + p0.y) / 2;
    if (_doLeft) {
      Coordinate offsetLeft = Coordinate(midX - uy, midY + ux);
      offsetPts.add(offsetLeft);
    }
    if (_doRight) {
      Coordinate offsetRight = Coordinate(midX + uy, midY - ux);
      offsetPts.add(offsetRight);
    }
  }
}
