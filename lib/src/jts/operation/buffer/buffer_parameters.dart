 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/angle.dart';

class BufferParameters {
  static const int CAP_ROUND = 1;

  static const int CAP_FLAT = 2;

  static const int CAP_SQUARE = 3;

  static const int JOIN_ROUND = 1;

  static const int JOIN_MITRE = 2;

  static const int JOIN_BEVEL = 3;

  static const int DEFAULT_QUADRANT_SEGMENTS = 8;

  static const double DEFAULT_MITRE_LIMIT = 5.0;

  static const double DEFAULT_SIMPLIFY_FACTOR = 0.01;

  int _quadrantSegments = DEFAULT_QUADRANT_SEGMENTS;

  int _endCapStyle = CAP_ROUND;

  int _joinStyle = JOIN_ROUND;

  double _mitreLimit = DEFAULT_MITRE_LIMIT;

  bool _isSingleSided = false;

  double _simplifyFactor = DEFAULT_SIMPLIFY_FACTOR;

  BufferParameters.empty();

  BufferParameters(int quadrantSegments, int endCapStyle, int joinStyle, double mitreLimit) {
    setQuadrantSegments(quadrantSegments);
    setEndCapStyle(endCapStyle);
    setJoinStyle(joinStyle);
    setMitreLimit(mitreLimit);
  }

  BufferParameters.of(int quadrantSegments) {
    setQuadrantSegments(quadrantSegments);
  }

  BufferParameters.of2(int quadrantSegments, int endCapStyle) {
    setQuadrantSegments(quadrantSegments);
    setEndCapStyle(endCapStyle);
  }

  int getQuadrantSegments() {
    return _quadrantSegments;
  }

  void setQuadrantSegments(int quadSegs) {
    _quadrantSegments = quadSegs;
  }

  static double bufferDistanceError(int quadSegs) {
    double alpha = Angle.piOver2 / quadSegs;
    return 1 - Math.cos(alpha / 2.0);
  }

  int getEndCapStyle() {
    return _endCapStyle;
  }

  void setEndCapStyle(int endCapStyle) {
    _endCapStyle = endCapStyle;
  }

  int getJoinStyle() {
    return _joinStyle;
  }

  void setJoinStyle(int joinStyle) {
    _joinStyle = joinStyle;
  }

  double getMitreLimit() {
    return _mitreLimit;
  }

  void setMitreLimit(double mitreLimit) {
    _mitreLimit = mitreLimit;
  }

  void setSingleSided(bool isSingleSided) {
    _isSingleSided = isSingleSided;
  }

  bool isSingleSided() {
    return _isSingleSided;
  }

  double getSimplifyFactor() {
    return _simplifyFactor;
  }

  void setSimplifyFactor(double simplifyFactor) {
    _simplifyFactor = (simplifyFactor < 0) ? 0 : simplifyFactor;
  }

  BufferParameters copy() {
    BufferParameters bp = BufferParameters.empty();
    bp._quadrantSegments = _quadrantSegments;
    bp._endCapStyle = _endCapStyle;
    bp._joinStyle = _joinStyle;
    bp._mitreLimit = _mitreLimit;
    return bp;
  }
}
