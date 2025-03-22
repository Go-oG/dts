import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/angle.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/util/affine_transformation.dart';

class GeometricShapeFactory {
  late GeometryFactory geomFact;
  late PrecisionModel precModel;

  Dimensions dim = Dimensions();

  int nPts = 100;

  double rotationAngle = 0.0;

  GeometricShapeFactory.empty() : this(GeometryFactory.empty());

  GeometricShapeFactory(this.geomFact) {
    precModel = geomFact.getPrecisionModel();
  }

  void setEnvelope(Envelope env) {
    dim.setEnvelope(env);
  }

  void setBase(Coordinate base) {
    dim.setBase(base);
  }

  void setCentre(Coordinate centre) {
    dim.setCentre(centre);
  }

  void setNumPoints(int nPts) {
    this.nPts = nPts;
  }

  void setSize(double size) {
    dim.setSize(size);
  }

  void setWidth(double width) {
    dim.setWidth(width);
  }

  void setHeight(double height) {
    dim.setHeight(height);
  }

  void setRotation(double radians) {
    rotationAngle = radians;
  }

  T rotate<T extends Geometry>(T geom) {
    if (rotationAngle != 0.0) {
      AffineTransformation trans = AffineTransformation.rotationInstance3(
        rotationAngle,
        dim.getCentre().x,
        dim.getCentre().y,
      );
      geom.apply2(trans);
    }
    return geom;
  }

  Polygon createRectangle() {
    int i;
    int ipt = 0;
    int nSide = nPts ~/ 4;
    if (nSide < 1) {
      nSide = 1;
    }

    double XsegLen = dim.getEnvelope().getWidth() / nSide;
    double YsegLen = dim.getEnvelope().getHeight() / nSide;
    Array<Coordinate> pts = Array((4 * nSide) + 1);
    Envelope env = dim.getEnvelope();
    for (i = 0; i < nSide; i++) {
      double x = env.getMinX() + (i * XsegLen);
      double y = env.getMinY();
      pts[ipt++] = coord(x, y);
    }
    for (i = 0; i < nSide; i++) {
      double x = env.getMaxX();
      double y = env.getMinY() + (i * YsegLen);
      pts[ipt++] = coord(x, y);
    }
    for (i = 0; i < nSide; i++) {
      double x = env.getMaxX() - (i * XsegLen);
      double y = env.getMaxY();
      pts[ipt++] = coord(x, y);
    }
    for (i = 0; i < nSide; i++) {
      double x = env.getMinX();
      double y = env.getMaxY() - (i * YsegLen);
      pts[ipt++] = coord(x, y);
    }
    pts[ipt++] = Coordinate.of(pts[0]);
    LinearRing ring = geomFact.createLinearRing2(pts);
    Polygon poly = geomFact.createPolygon(ring);
    return rotate(poly);
  }

  Polygon createCircle() {
    return createEllipse();
  }

  Polygon createEllipse() {
    Envelope env = dim.getEnvelope();
    double xRadius = env.getWidth() / 2.0;
    double yRadius = env.getHeight() / 2.0;
    double centreX = env.getMinX() + xRadius;
    double centreY = env.getMinY() + yRadius;
    Array<Coordinate> pts = Array(nPts + 1);
    int iPt = 0;
    for (int i = 0; i < nPts; i++) {
      double ang = i * ((2 * Math.pi) / nPts);
      double x = (xRadius * Angle.cosSnap(ang)) + centreX;
      double y = (yRadius * Angle.sinSnap(ang)) + centreY;
      pts[iPt++] = coord(x, y);
    }
    pts[iPt] = Coordinate.of(pts[0]);
    LinearRing ring = geomFact.createLinearRing2(pts);
    Polygon poly = geomFact.createPolygon(ring);
    return rotate(poly);
  }

  Polygon createSquircle() {
    return createSupercircle(4);
  }

  Polygon createSupercircle(double power) {
    double recipPow = 1.0 / power;
    double radius = dim.getMinSize() / 2;
    Coordinate centre = dim.getCentre();
    double r4 = Math.pow(radius, power);
    double y0 = radius;
    double xyInt = Math.pow(r4 / 2, recipPow);
    int nSegsInOct = nPts ~/ 8;
    int totPts = (nSegsInOct * 8) + 1;
    Array<Coordinate> pts = Array(totPts);
    double xInc = xyInt / nSegsInOct;
    for (int i = 0; i <= nSegsInOct; i++) {
      double x = 0.0;
      double y = y0;
      if (i != 0) {
        x = xInc * i;
        double x4 = Math.pow(x, power);
        y = Math.pow(r4 - x4, recipPow);
      }
      pts[i] = coordTrans(x, y, centre);
      pts[(2 * nSegsInOct) - i] = coordTrans(y, x, centre);
      pts[(2 * nSegsInOct) + i] = coordTrans(y, -x, centre);
      pts[(4 * nSegsInOct) - i] = coordTrans(x, -y, centre);
      pts[(4 * nSegsInOct) + i] = coordTrans(-x, -y, centre);
      pts[(6 * nSegsInOct) - i] = coordTrans(-y, -x, centre);
      pts[(6 * nSegsInOct) + i] = coordTrans(-y, x, centre);
      pts[(8 * nSegsInOct) - i] = coordTrans(-x, y, centre);
    }
    pts[pts.length - 1] = Coordinate.of(pts[0]);
    LinearRing ring = geomFact.createLinearRing2(pts);
    Polygon poly = geomFact.createPolygon(ring);
    return rotate(poly);
  }

  LineString createArc(double startAng, double angExtent) {
    Envelope env = dim.getEnvelope();
    double xRadius = env.getWidth() / 2.0;
    double yRadius = env.getHeight() / 2.0;
    double centreX = env.getMinX() + xRadius;
    double centreY = env.getMinY() + yRadius;
    double angSize = angExtent;
    if ((angSize <= 0.0) || (angSize > Angle.piTimes2)) {
      angSize = Angle.piTimes2;
    }

    double angInc = angSize / (nPts - 1);
    Array<Coordinate> pts = Array(nPts);
    int iPt = 0;
    for (int i = 0; i < nPts; i++) {
      double ang = startAng + (i * angInc);
      double x = (xRadius * Angle.cosSnap(ang)) + centreX;
      double y = (yRadius * Angle.sinSnap(ang)) + centreY;
      pts[iPt++] = coord(x, y);
    }
    LineString line = geomFact.createLineString2(pts);
    return rotate(line);
  }

  Polygon createArcPolygon(double startAng, double angExtent) {
    Envelope env = dim.getEnvelope();
    double xRadius = env.getWidth() / 2.0;
    double yRadius = env.getHeight() / 2.0;
    double centreX = env.getMinX() + xRadius;
    double centreY = env.getMinY() + yRadius;
    double angSize = angExtent;
    if ((angSize <= 0.0) || (angSize > Angle.piTimes2)) {
      angSize = Angle.piTimes2;
    }

    double angInc = angSize / (nPts - 1);
    Array<Coordinate> pts = Array(nPts + 2);
    int iPt = 0;
    pts[iPt++] = coord(centreX, centreY);
    for (int i = 0; i < nPts; i++) {
      double ang = startAng + (angInc * i);
      double x = (xRadius * Angle.cosSnap(ang)) + centreX;
      double y = (yRadius * Angle.sinSnap(ang)) + centreY;
      pts[iPt++] = coord(x, y);
    }
    pts[iPt++] = coord(centreX, centreY);
    LinearRing ring = geomFact.createLinearRing2(pts);
    Polygon poly = geomFact.createPolygon(ring);
    return rotate(poly);
  }

  Coordinate coord(double x, double y) {
    Coordinate pt = Coordinate(x, y);
    precModel.makePrecise(pt);
    return pt;
  }

  Coordinate coordTrans(double x, double y, Coordinate trans) {
    return coord(x + trans.x, y + trans.y);
  }
}

class Dimensions {
  Coordinate? base;
  Coordinate? centre;
  double width = 0;
  double height = 0;

  void setBase(Coordinate base) {
    this.base = base;
  }

  Coordinate? getBase() {
    return base;
  }

  void setCentre(Coordinate centre) {
    this.centre = centre;
  }

  Coordinate getCentre() {
    centre ??= Coordinate(base!.x + (width / 2), base!.y + (height / 2));
    return centre!;
  }

  void setSize(double size) {
    height = size;
    width = size;
  }

  double getMinSize() {
    return Math.minD(width, height);
  }

  void setWidth(double width) {
    this.width = width;
  }

  double getWidth() {
    return width;
  }

  double getHeight() {
    return height;
  }

  void setHeight(double height) {
    this.height = height;
  }

  void setEnvelope(Envelope env) {
    width = env.getWidth();
    height = env.getHeight();
    base = Coordinate(env.getMinX(), env.getMinY());
    centre = Coordinate.of(env.centre()!);
  }

  Envelope getEnvelope() {
    if (base != null) {
      return Envelope.of4(base!.x, base!.x + width, base!.y, base!.y + height);
    }
    if (centre != null) {
      return Envelope.of4(
        centre!.x - (width / 2),
        centre!.x + (width / 2),
        centre!.y - (height / 2),
        centre!.y + (height / 2),
      );
    }
    return Envelope.of4(0, width, 0, height);
  }
}
