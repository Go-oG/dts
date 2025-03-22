 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/distance/discrete_hausdorff_distance.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_filter.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/util/linear_component_extracter.dart';
import 'package:dts/src/jts/operation/distance/distance_op.dart';

import '../../../geom/geometry_collection.dart';
import '../../../geom/multi_polygon.dart';

class BufferDistanceValidator {
  static const double _MAX_DISTANCE_DIFF_FRAC = 0.012;

  Geometry input;

  final double _bufDistance;

  Geometry result;

  double _minValidDistance = 0;

  double _maxValidDistance = 0;

  double _minDistanceFound = 0;

  double _maxDistanceFound = 0;

  bool isValid = true;

  String? _errMsg;

  Coordinate? _errorLocation;

  Geometry? _errorIndicator;

  BufferDistanceValidator(this.input, this._bufDistance, this.result);

  bool isValidF() {
    double posDistance = Math.abs(_bufDistance);
    double distDelta = _MAX_DISTANCE_DIFF_FRAC * posDistance;
    _minValidDistance = posDistance - distDelta;
    _maxValidDistance = posDistance + distDelta;
    if (input.isEmpty() || result.isEmpty()) {
      return true;
    }

    if (_bufDistance > 0.0) {
      checkPositiveValid();
    } else {
      checkNegativeValid();
    }
    return isValid;
  }

  String? getErrorMessage() {
    return _errMsg;
  }

  Coordinate? getErrorLocation() {
    return _errorLocation;
  }

  Geometry? getErrorIndicator() {
    return _errorIndicator;
  }

  void checkPositiveValid() {
    Geometry bufCurve = result.getBoundary()!;
    checkMinimumDistance(input, bufCurve, _minValidDistance);
    if (!isValid) return;

    checkMaximumDistance(input, bufCurve, _maxValidDistance);
  }

  void checkNegativeValid() {
    if (!((input is Polygon) || (input is MultiPolygon)) || (input is GeometryCollection)) {
      return;
    }
    Geometry inputCurve = getPolygonLines(input);
    checkMinimumDistance(inputCurve, result, _minValidDistance);
    if (!isValid) {
      return;
    }

    checkMaximumDistance(inputCurve, result, _maxValidDistance);
  }

  Geometry getPolygonLines(Geometry g) {
    List<LineString> lines = [];
    final lineExtracter = LinearComponentExtracter(lines);
    final polys = PolygonExtracter.getPolygons(g);
    for (var poly in polys) {
      poly.apply4(lineExtracter);
    }
    return g.factory.buildGeometry(lines);
  }

  void checkMinimumDistance(Geometry g1, Geometry g2, double minDist) {
    final distOp = DistanceOp(g1, g2, minDist);
    _minDistanceFound = distOp.distance();
    if (_minDistanceFound < minDist) {
      isValid = false;
      Array<Coordinate> pts = distOp.nearestPoints();
      _errorLocation = distOp.nearestPoints()[1];
      _errorIndicator = g1.factory.createLineString2(pts);
      _errMsg = "Distance between buffer curve and input is too small ($_minDistanceFound at)";
    }
  }

  void checkMaximumDistance(Geometry input, Geometry bufCurve, double maxDist) {
    final haus = DiscreteHausdorffDistance(bufCurve, input);
    haus.setDensifyFraction(0.25);
    _maxDistanceFound = haus.orientedDistance();
    if (_maxDistanceFound > maxDist) {
      isValid = false;
      Array<Coordinate> pts = haus.getCoordinates();
      _errorLocation = pts[1];
      _errorIndicator = input.factory.createLineString2(pts);
      _errMsg = "Distance between buffer curve and input is too large ($_maxDistanceFound)})";
    }
  }
}
