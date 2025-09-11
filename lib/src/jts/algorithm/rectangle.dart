import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';

class Rectangle {
  static Polygon createFromSidePts(
    Coordinate baseRightPt,
    Coordinate baseLeftPt,
    Coordinate oppositePt,
    Coordinate leftSidePt,
    Coordinate rightSidePt,
    GeometryFactory factory,
  ) {
    double dx = baseLeftPt.x - baseRightPt.x;
    double dy = baseLeftPt.y - baseRightPt.y;
    double baseC = _computeLineEquationC(dx, dy, baseRightPt);
    double oppC = _computeLineEquationC(dx, dy, oppositePt);
    double leftC = _computeLineEquationC(-dy, dx, leftSidePt);
    double rightC = _computeLineEquationC(-dy, dx, rightSidePt);
    LineSegment baseLine = _createLineForStandardEquation(-dy, dx, baseC);
    LineSegment oppLine = _createLineForStandardEquation(-dy, dx, oppC);
    LineSegment leftLine = _createLineForStandardEquation(-dx, -dy, leftC);
    LineSegment rightLine = _createLineForStandardEquation(-dx, -dy, rightC);
    Coordinate? p0 = (rightSidePt.equals2D(baseRightPt))
        ? baseRightPt.copy()
        : baseLine.lineIntersection(rightLine);
    Coordinate? p1 = (leftSidePt.equals2D(baseLeftPt))
        ? baseLeftPt.copy()
        : baseLine.lineIntersection(leftLine);
    Coordinate? p2 = (leftSidePt.equals2D(oppositePt))
        ? oppositePt.copy()
        : oppLine.lineIntersection(leftLine);
    Coordinate? p3 = (rightSidePt.equals2D(oppositePt))
        ? oppositePt.copy()
        : oppLine.lineIntersection(rightLine);
    LinearRing shell =
        factory.createLinearRings([p0!, p1!, p2!, p3!, p0.copy()]);
    return factory.createPolygon(shell);
  }

  static double _computeLineEquationC(double a, double b, Coordinate p) =>
      (a * p.y) - (b * p.x);

  static LineSegment _createLineForStandardEquation(
      double a, double b, double c) {
    Coordinate p0;
    Coordinate p1;
    if (b.abs() > a.abs()) {
      p0 = Coordinate(0.0, c / b);
      p1 = Coordinate(1.0, (c / b) - (a / b));
    } else {
      p0 = Coordinate(c / a, 0.0);
      p1 = Coordinate((c / a) - (b / a), 1.0);
    }
    return LineSegment(p0, p1);
  }
}
