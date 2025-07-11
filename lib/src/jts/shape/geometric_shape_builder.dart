import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

abstract class GeometricShapeBuilder {
  Envelope? extent = Envelope.fromLTRB(0, 0, 1, 1);
  int numPts = 0;

  GeometryFactory geomFactory;

  GeometricShapeBuilder(this.geomFactory);

  void setExtent(Envelope extent) {
    this.extent = extent;
  }

  Envelope? getExtent() => extent;

  Coordinate? getCentre() {
    return extent!.centre();
  }

  double getDiameter() => extent!.shortSide;

  double getRadius() {
    return getDiameter() / 2;
  }

  LineSegment getSquareBaseLine() {
    double radius = getRadius();
    Coordinate centre = getCentre()!;
    Coordinate p0 = Coordinate(centre.x - radius, centre.y - radius);
    Coordinate p1 = Coordinate(centre.x + radius, centre.y - radius);
    return LineSegment(p0, p1);
  }

  Envelope getSquareExtent() {
    double radius = getRadius();
    Coordinate centre = getCentre()!;
    return Envelope.fromLTRB(
        centre.x - radius, centre.y - radius, centre.x + radius, centre.y + radius);
  }

  void setNumPoints(int numPts) {
    this.numPts = numPts;
  }

  Geometry getGeometry();

  Coordinate createCoord(double x, double y) {
    Coordinate pt = Coordinate(x, y);
    geomFactory.getPrecisionModel().makePrecise(pt);
    return pt;
  }
}
