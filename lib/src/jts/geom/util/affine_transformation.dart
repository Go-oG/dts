import 'package:d_util/d_util.dart';

import '../../math/math.dart';
import '../coordinate.dart';
import '../coordinate_sequence.dart';
import '../geometry.dart';

class AffineTransformation implements CoordinateSequenceFilter {
  static AffineTransformation reflectionInstance(double x0, double y0, double x1, double y1) {
    AffineTransformation trans = AffineTransformation();
    trans.setToReflection2(x0, y0, x1, y1);
    return trans;
  }

  static AffineTransformation reflectionInstance2(double x, double y) {
    AffineTransformation trans = AffineTransformation();
    trans.setToReflection(x, y);
    return trans;
  }

  static AffineTransformation rotationInstance(double theta) {
    return rotationInstance2(Math.sin(theta), Math.cos(theta));
  }

  static AffineTransformation rotationInstance2(double sinTheta, double cosTheta) {
    AffineTransformation trans = AffineTransformation();
    trans.setToRotation2(sinTheta, cosTheta);
    return trans;
  }

  static AffineTransformation rotationInstance3(double theta, double x, double y) {
    return rotationInstance4(Math.sin(theta), Math.cos(theta), x, y);
  }

  static AffineTransformation rotationInstance4(
      double sinTheta, double cosTheta, double x, double y) {
    AffineTransformation trans = AffineTransformation();
    trans.setToRotation4(sinTheta, cosTheta, x, y);
    return trans;
  }

  static AffineTransformation scaleInstance(double xScale, double yScale) {
    AffineTransformation trans = AffineTransformation();
    trans.setToScale(xScale, yScale);
    return trans;
  }

  static AffineTransformation scaleInstance2(double xScale, double yScale, double x, double y) {
    AffineTransformation trans = AffineTransformation();
    trans.translate(-x, -y);
    trans.scale(xScale, yScale);
    trans.translate(x, y);
    return trans;
  }

  static AffineTransformation shearInstance(double xShear, double yShear) {
    AffineTransformation trans = AffineTransformation();
    trans.setToShear(xShear, yShear);
    return trans;
  }

  static AffineTransformation translationInstance(double x, double y) {
    AffineTransformation trans = AffineTransformation();
    trans.setToTranslation(x, y);
    return trans;
  }

  late double _m00;

  late double _m01;

  late double _m02;

  late double _m10;

  late double _m11;

  late double _m12;

  AffineTransformation() {
    setToIdentity();
  }

  AffineTransformation.of(Array<double> matrix) {
    _m00 = matrix[0];
    _m01 = matrix[1];
    _m02 = matrix[2];
    _m10 = matrix[3];
    _m11 = matrix[4];
    _m12 = matrix[5];
  }

  AffineTransformation.of2(double m00, double m01, double m02, double m10, double m11, double m12) {
    setTransformation2(m00, m01, m02, m10, m11, m12);
  }

  AffineTransformation.of3(AffineTransformation trans) {
    setTransformation(trans);
  }

  AffineTransformation.of4(
    Coordinate src0,
    Coordinate src1,
    Coordinate src2,
    Coordinate dest0,
    Coordinate dest1,
    Coordinate dest2,
  ) {
    throw ("Use AffineTransformationFactory instead");
  }

  AffineTransformation setToIdentity() {
    _m00 = 1.0;
    _m01 = 0.0;
    _m02 = 0.0;
    _m10 = 0.0;
    _m11 = 1.0;
    _m12 = 0.0;
    return this;
  }

  AffineTransformation setTransformation2(
      double m00, double m01, double m02, double m10, double m11, double m12) {
    _m00 = m00;
    _m01 = m01;
    _m02 = m02;
    _m10 = m10;
    _m11 = m11;
    _m12 = m12;
    return this;
  }

  AffineTransformation setTransformation(AffineTransformation trans) {
    _m00 = trans._m00;
    _m01 = trans._m01;
    _m02 = trans._m02;
    _m10 = trans._m10;
    _m11 = trans._m11;
    _m12 = trans._m12;
    return this;
  }

  Array<double> getMatrixEntries() {
    return [_m00, _m01, _m02, _m10, _m11, _m12].toArray();
  }

  double getDeterminant() {
    return (_m00 * _m11) - (_m01 * _m10);
  }

  AffineTransformation getInverse() {
    double det = getDeterminant();
    if (det == 0) {
      throw "Transformation is non-invertible";
    }

    double im00 = _m11 / det;
    double im10 = (-_m10) / det;
    double im01 = (-_m01) / det;
    double im11 = _m00 / det;
    double im02 = ((_m01 * _m12) - (_m02 * _m11)) / det;
    double im12 = (((-_m00) * _m12) + (_m10 * _m02)) / det;
    return AffineTransformation.of2(im00, im01, im02, im10, im11, im12);
  }

  AffineTransformation setToReflectionBasic(double x0, double y0, double x1, double y1) {
    if ((x0 == x1) && (y0 == y1)) {
      throw IllegalArgumentException("Reflection line points must be distinct");
    }
    double dx = x1 - x0;
    double dy = y1 - y0;
    double d = MathUtil.hypot(dx, dy);
    double sin = dy / d;
    double cos = dx / d;
    double cs2 = (2 * sin) * cos;
    double c2s2 = (cos * cos) - (sin * sin);
    _m00 = c2s2;
    _m01 = cs2;
    _m02 = 0.0;
    _m10 = cs2;
    _m11 = -c2s2;
    _m12 = 0.0;
    return this;
  }

  AffineTransformation setToReflection2(double x0, double y0, double x1, double y1) {
    if ((x0 == x1) && (y0 == y1)) {
      throw IllegalArgumentException("Reflection line points must be distinct");
    }
    setToTranslation(-x0, -y0);
    double dx = x1 - x0;
    double dy = y1 - y0;
    double d = MathUtil.hypot(dx, dy);
    double sin = dy / d;
    double cos = dx / d;
    rotate2(-sin, cos);
    scale(1, -1);
    rotate2(sin, cos);
    translate(x0, y0);
    return this;
  }

  AffineTransformation setToReflection(double x, double y) {
    if ((x == 0.0) && (y == 0.0)) {
      throw IllegalArgumentException("Reflection vector must be non-zero");
    }
    if (x == y) {
      _m00 = 0.0;
      _m01 = 1.0;
      _m02 = 0.0;
      _m10 = 1.0;
      _m11 = 0.0;
      _m12 = 0.0;
      return this;
    }
    double d = MathUtil.hypot(x, y);
    double sin = y / d;
    double cos = x / d;
    rotate2(-sin, cos);
    scale(1, -1);
    rotate2(sin, cos);
    return this;
  }

  AffineTransformation setToRotation(double theta) {
    setToRotation2(Math.sin(theta), Math.cos(theta));
    return this;
  }

  AffineTransformation setToRotation2(double sinTheta, double cosTheta) {
    _m00 = cosTheta;
    _m01 = -sinTheta;
    _m02 = 0.0;
    _m10 = sinTheta;
    _m11 = cosTheta;
    _m12 = 0.0;
    return this;
  }

  AffineTransformation setToRotation3(double theta, double x, double y) {
    setToRotation4(Math.sin(theta), Math.cos(theta), x, y);
    return this;
  }

  AffineTransformation setToRotation4(double sinTheta, double cosTheta, double x, double y) {
    _m00 = cosTheta;
    _m01 = -sinTheta;
    _m02 = (x - (x * cosTheta)) + (y * sinTheta);
    _m10 = sinTheta;
    _m11 = cosTheta;
    _m12 = (y - (x * sinTheta)) - (y * cosTheta);
    return this;
  }

  AffineTransformation setToScale(double xScale, double yScale) {
    _m00 = xScale;
    _m01 = 0.0;
    _m02 = 0.0;
    _m10 = 0.0;
    _m11 = yScale;
    _m12 = 0.0;
    return this;
  }

  AffineTransformation setToShear(double xShear, double yShear) {
    _m00 = 1.0;
    _m01 = xShear;
    _m02 = 0.0;
    _m10 = yShear;
    _m11 = 1.0;
    _m12 = 0.0;
    return this;
  }

  AffineTransformation setToTranslation(double dx, double dy) {
    _m00 = 1.0;
    _m01 = 0.0;
    _m02 = dx;
    _m10 = 0.0;
    _m11 = 1.0;
    _m12 = dy;
    return this;
  }

  AffineTransformation reflect2(double x0, double y0, double x1, double y1) {
    compose(reflectionInstance(x0, y0, x1, y1));
    return this;
  }

  AffineTransformation reflect(double x, double y) {
    compose(reflectionInstance2(x, y));
    return this;
  }

  AffineTransformation rotate(double theta) {
    compose(rotationInstance(theta));
    return this;
  }

  AffineTransformation rotate2(double sinTheta, double cosTheta) {
    compose(rotationInstance2(sinTheta, cosTheta));
    return this;
  }

  AffineTransformation rotate3(double theta, double x, double y) {
    compose(rotationInstance3(theta, x, y));
    return this;
  }

  AffineTransformation rotate4(double sinTheta, double cosTheta, double x, double y) {
    compose(rotationInstance4(sinTheta, cosTheta, x, y));
    return this;
  }

  AffineTransformation scale(double xScale, double yScale) {
    compose(scaleInstance(xScale, yScale));
    return this;
  }

  AffineTransformation shear(double xShear, double yShear) {
    compose(shearInstance(xShear, yShear));
    return this;
  }

  AffineTransformation translate(double x, double y) {
    compose(translationInstance(x, y));
    return this;
  }

  AffineTransformation compose(AffineTransformation trans) {
    double mp00 = (trans._m00 * _m00) + (trans._m01 * _m10);
    double mp01 = (trans._m00 * _m01) + (trans._m01 * _m11);
    double mp02 = ((trans._m00 * _m02) + (trans._m01 * _m12)) + trans._m02;
    double mp10 = (trans._m10 * _m00) + (trans._m11 * _m10);
    double mp11 = (trans._m10 * _m01) + (trans._m11 * _m11);
    double mp12 = ((trans._m10 * _m02) + (trans._m11 * _m12)) + trans._m12;
    _m00 = mp00;
    _m01 = mp01;
    _m02 = mp02;
    _m10 = mp10;
    _m11 = mp11;
    _m12 = mp12;
    return this;
  }

  AffineTransformation composeBefore(AffineTransformation trans) {
    double mp00 = (_m00 * trans._m00) + (_m01 * trans._m10);
    double mp01 = (_m00 * trans._m01) + (_m01 * trans._m11);
    double mp02 = ((_m00 * trans._m02) + (_m01 * trans._m12)) + _m02;
    double mp10 = (_m10 * trans._m00) + (_m11 * trans._m10);
    double mp11 = (_m10 * trans._m01) + (_m11 * trans._m11);
    double mp12 = ((_m10 * trans._m02) + (_m11 * trans._m12)) + _m12;
    _m00 = mp00;
    _m01 = mp01;
    _m02 = mp02;
    _m10 = mp10;
    _m11 = mp11;
    _m12 = mp12;
    return this;
  }

  Coordinate transform3(Coordinate src, Coordinate dest) {
    double xp = ((_m00 * src.x) + (_m01 * src.y)) + _m02;
    double yp = ((_m10 * src.x) + (_m11 * src.y)) + _m12;
    dest.x = xp;
    dest.y = yp;
    return dest;
  }

  Geometry transform(Geometry g) {
    Geometry g2 = g.copy();
    g2.apply2(this);
    return g2;
  }

  void transform2(CoordinateSequence seq, int i) {
    double xp = ((_m00 * seq.getOrdinate(i, 0)) + (_m01 * seq.getOrdinate(i, 1))) + _m02;
    double yp = ((_m10 * seq.getOrdinate(i, 0)) + (_m11 * seq.getOrdinate(i, 1))) + _m12;
    seq.setOrdinate(i, 0, xp);
    seq.setOrdinate(i, 1, yp);
  }

  @override
  void filter(CoordinateSequence seq, int i) {
    transform2(seq, i);
  }

  @override
  bool isGeometryChanged() {
    return true;
  }

  @override
  bool isDone() {
    return false;
  }

  bool isIdentity() {
    return (((((_m00 == 1) && (_m01 == 0)) && (_m02 == 0)) && (_m10 == 0)) && (_m11 == 1)) &&
        (_m12 == 0);
  }

  @override
  int get hashCode {
    final int prime = 31;
    int result = 1;
    int temp;
    temp = Double.doubleToLongBits(_m00);
    result = (prime * result) + ((temp ^ (temp >>> 32)));
    temp = Double.doubleToLongBits(_m01);
    result = (prime * result) + ((temp ^ (temp >>> 32)));
    temp = Double.doubleToLongBits(_m02);
    result = (prime * result) + ((temp ^ (temp >>> 32)));
    temp = Double.doubleToLongBits(_m10);
    result = (prime * result) + ((temp ^ (temp >>> 32)));
    temp = Double.doubleToLongBits(_m11);
    result = (prime * result) + ((temp ^ (temp >>> 32)));
    temp = Double.doubleToLongBits(_m12);
    result = (prime * result) + ((temp ^ (temp >>> 32)));
    return result;
  }

  AffineTransformation clone() {
    return AffineTransformation.of3(this);
  }

  @override
  bool operator ==(Object other) {
    if (other is! AffineTransformation) {
      return false;
    }

    return _m00 == other._m00 &&
        _m01 == other._m01 &&
        _m02 == other._m02 &&
        _m10 == other._m10 &&
        _m11 == other._m11 &&
        _m12 == other._m12;
  }
}
