import 'dart:math';

import 'package:d_util/d_util.dart';

import '../../util/geometric_shape_factory.dart';
import '../coordinate.dart';
import '../envelope.dart';
import '../geometry.dart';
import '../linear_ring.dart';

class SineStarFactory extends GeometricShapeFactory {
  static Geometry create(Coordinate origin, double size, int nPts, int nArms,
      double armLengthRatio) {
    SineStarFactory gsf = SineStarFactory();
    gsf.setCentre(origin);
    gsf.setSize(size);
    gsf.setNumPoints(nPts);
    gsf.setArmLengthRatio(armLengthRatio);
    gsf.setNumArms(nArms);
    Geometry poly = gsf.createSineStar();
    return poly;
  }

  int numArms = 8;

  double armLengthRatio = 0.5;

  SineStarFactory() : super();

  SineStarFactory.of(super.geomFact);

  void setNumArms(int numArms) {
    this.numArms = numArms;
  }

  void setArmLengthRatio(double armLengthRatio) {
    this.armLengthRatio = armLengthRatio;
  }

  Geometry createSineStar() {
    Envelope env = dim.getEnvelope();
    double radius = env.width / 2.0;
    double armRatio = armLengthRatio;
    if (armRatio < 0.0) armRatio = 0.0;

    if (armRatio > 1.0) armRatio = 1.0;

    double armMaxLen = armRatio * radius;
    double insideRadius = (1 - armRatio) * radius;
    double centreX = env.minX + radius;
    double centreY = env.minY + radius;
    Array<Coordinate> pts = Array(nPts + 1);
    int iPt = 0;
    for (int i = 0; i < nPts; i++) {
      double ptArcFrac = (i / nPts) * numArms;
      double armAngFrac = ptArcFrac - Math.floor(ptArcFrac);
      double armAng = (2 * pi) * armAngFrac;
      double armLenFrac = (Math.cos(armAng) + 1.0) / 2.0;
      double curveRadius = insideRadius + (armMaxLen * armLenFrac);
      double ang = i * ((2 * pi) / nPts);
      double x = (curveRadius * Math.cos(ang)) + centreX;
      double y = (curveRadius * Math.sin(ang)) + centreY;
      pts[iPt++] = coord(x, y);
    }
    pts[iPt] = Coordinate.of(pts[0]);
    LinearRing ring = geomFact.createLinearRings(pts.toList());
    return geomFact.createPolygon(ring);
  }
}
