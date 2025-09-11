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
  late final GeometryFactory geomFact;
  late final PrecisionModel precModel;
  final Dimensions dim = Dimensions();
  int nPts = 100;
  double rotationAngle = 0.0;

  GeometricShapeFactory([GeometryFactory? gf]) {
    geomFact = gf ?? GeometryFactory();
    precModel = geomFact.getPrecisionModel();
  }

  void setEnvelope(Envelope env) {
    dim.setEnvelope(env);
  }

  void setBase(Coordinate base) => dim.base = base;

  void setCentre(Coordinate centre) => dim.centre = centre;

  void setNumPoints(int nPts) => this.nPts = nPts;

  void setSize(double size) => dim.setSize(size);

  void setWidth(double width) => dim.setWidth(width);

  void setHeight(double height) => dim.setHeight(height);

  void setRotation(double radians) => rotationAngle = radians;

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

    double xSegLen = dim.getEnvelope().width / nSide;
    double ySegLen = dim.getEnvelope().height / nSide;
    Array<Coordinate> pts = Array((4 * nSide) + 1);
    Envelope env = dim.getEnvelope();
    for (i = 0; i < nSide; i++) {
      double x = env.minX + (i * xSegLen);
      double y = env.minY;
      pts[ipt++] = coord(x, y);
    }
    for (i = 0; i < nSide; i++) {
      double x = env.maxX;
      double y = env.minY + (i * ySegLen);
      pts[ipt++] = coord(x, y);
    }
    for (i = 0; i < nSide; i++) {
      double x = env.maxX - (i * xSegLen);
      double y = env.maxY;
      pts[ipt++] = coord(x, y);
    }
    for (i = 0; i < nSide; i++) {
      double x = env.minX;
      double y = env.maxY - (i * ySegLen);
      pts[ipt++] = coord(x, y);
    }
    pts[ipt++] = Coordinate.of(pts[0]);
    LinearRing ring = geomFact.createLinearRings(pts.toList());
    Polygon poly = geomFact.createPolygon(ring);
    return rotate(poly);
  }

  Polygon createCircle() => createEllipse();

  Polygon createEllipse() {
    Envelope env = dim.getEnvelope();
    double xRadius = env.width / 2.0;
    double yRadius = env.height / 2.0;
    double centreX = env.minX + xRadius;
    double centreY = env.minY + yRadius;
    Array<Coordinate> pts = Array(nPts + 1);
    int iPt = 0;
    for (int i = 0; i < nPts; i++) {
      double ang = i * ((2 * Math.pi) / nPts);
      double x = (xRadius * Angle.cosSnap(ang)) + centreX;
      double y = (yRadius * Angle.sinSnap(ang)) + centreY;
      pts[iPt++] = coord(x, y);
    }
    pts[iPt] = Coordinate.of(pts[0]);
    LinearRing ring = geomFact.createLinearRings(pts.toList());
    Polygon poly = geomFact.createPolygon(ring);
    return rotate(poly);
  }

  Polygon createSquircle() => createSupercircle(4);

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
    LinearRing ring = geomFact.createLinearRings(pts.toList());
    Polygon poly = geomFact.createPolygon(ring);
    return rotate(poly);
  }

  LineString createArc(double startAng, double angExtent) {
    Envelope env = dim.getEnvelope();
    double xRadius = env.width / 2.0;
    double yRadius = env.height / 2.0;
    double centreX = env.minX + xRadius;
    double centreY = env.minY + yRadius;
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
    LineString line = geomFact.createLineString2(pts.toList());
    return rotate(line);
  }

  Polygon createArcPolygon(double startAng, double angExtent) {
    Envelope env = dim.getEnvelope();
    double xRadius = env.width / 2.0;
    double yRadius = env.height / 2.0;
    double centreX = env.minX + xRadius;
    double centreY = env.minY + yRadius;
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
    LinearRing ring = geomFact.createLinearRings(pts.toList());
    Polygon poly = geomFact.createPolygon(ring);
    return rotate(poly);
  }

  Coordinate coord(double x, double y) {
    final pt = Coordinate(x, y);
    precModel.makePrecise(pt);
    return pt;
  }

  Coordinate coordTrans(double x, double y, Coordinate trans) => coord(x + trans.x, y + trans.y);
}

final class Dimensions {
  Coordinate? base;
  Coordinate? centre;
  double width = 0;
  double height = 0;

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
    width = env.width;
    height = env.height;
    base = Coordinate(env.minX, env.minY);
    centre = Coordinate.of(env.centre()!);
  }

  Envelope getEnvelope() {
    final base = this.base;

    if (base != null) {
      return Envelope.fromLTRB(base.x, base.y, base.x + width, base.y + height);
    }
    final centre = this.centre;
    if (centre != null) {
      return Envelope.fromLTRB(
        centre.x - width / 2,
        centre.y - height / 2,
        centre.x + width / 2,
        centre.y + height / 2,
      );
    }
    return Envelope.fromLTRB(0, 0, width, height);
  }
}
