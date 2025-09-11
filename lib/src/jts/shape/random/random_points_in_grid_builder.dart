import 'dart:math';

import 'package:d_util/d_util.dart' show Math;
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/math/math.dart';
import 'package:dts/src/jts/shape/geometric_shape_builder.dart';

class RandomPointsInGridBuilder extends GeometricShapeBuilder {
  bool _isConstrainedToCircle = false;

  double _gutterFraction = 0;

  RandomPointsInGridBuilder.empty() : super(GeometryFactory());

  RandomPointsInGridBuilder(super.geomFact);

  void setConstrainedToCircle(bool isConstrainedToCircle) {
    _isConstrainedToCircle = isConstrainedToCircle;
  }

  void setGutterFraction(double gutterFraction) {
    _gutterFraction = gutterFraction;
  }

  @override
  Geometry getGeometry() {
    int nCells = (sqrt(numPts).toInt());
    if ((nCells * nCells) < numPts) {
      nCells += 1;
    }

    double gridDX = getExtent()!.width / nCells;
    double gridDY = getExtent()!.height / nCells;
    double gutterFrac = MathUtil.clamp2(_gutterFraction, 0.0, 1.0);
    double gutterOffsetX = (gridDX * gutterFrac) / 2;
    double gutterOffsetY = (gridDY * gutterFrac) / 2;
    double cellFrac = 1.0 - gutterFrac;
    double cellDX = cellFrac * gridDX;
    double cellDY = cellFrac * gridDY;
    List<Coordinate> pts = [];

    for (int i = 0; i < nCells; i++) {
      for (int j = 0; j < nCells; j++) {
        double orgX = (getExtent()!.minX + (i * gridDX)) + gutterOffsetX;
        double orgY = (getExtent()!.minY + (j * gridDY)) + gutterOffsetY;
        pts.add(randomPointInCell(orgX, orgY, cellDX, cellDY));
      }
    }
    return geomFactory.createMultiPoint4(pts);
  }

  Coordinate randomPointInCell(
      double orgX, double orgY, double xLen, double yLen) {
    if (_isConstrainedToCircle) {
      return randomPointInCircle(orgX, orgY, xLen, yLen);
    }
    return randomPointInGridCell(orgX, orgY, xLen, yLen);
  }

  Coordinate randomPointInGridCell(
      double orgX, double orgY, double xLen, double yLen) {
    double x = orgX + (xLen * Math.random());
    double y = orgY + (yLen * Math.random());
    return createCoord(x, y);
  }

  static Coordinate randomPointInCircle(
      double orgX, double orgY, double width, double height) {
    double centreX = orgX + (width / 2);
    double centreY = orgY + (height / 2);
    double rndAng = (2 * pi) * Math.random();
    double rndRadius = Math.random();
    double rndRadius2 = sqrt(rndRadius);
    double rndX = ((width / 2) * rndRadius2) * cos(rndAng);
    double rndY = ((height / 2) * rndRadius2) * sin(rndAng);
    double x0 = centreX + rndX;
    double y0 = centreY + rndY;
    return Coordinate(x0, y0);
  }
}
