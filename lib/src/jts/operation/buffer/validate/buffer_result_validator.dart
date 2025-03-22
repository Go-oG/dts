import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'buffer_distance_validator.dart';

class BufferResultValidator {
  static bool VERBOSE = false;

  static const double _MAX_ENV_DIFF_FRAC = 0.012;

  static bool isValid2(Geometry g, double distance, Geometry result) {
    final validator = BufferResultValidator(g, distance, result);
    if (validator.isValidF()) return true;

    return false;
  }

  static String? isValidMsg(Geometry g, double distance, Geometry result) {
    BufferResultValidator validator = BufferResultValidator(g, distance, result);
    if (!validator.isValidF()) return validator.getErrorMessage();

    return null;
  }

  Geometry input;

  double distance;

  Geometry result;

  bool isValid = true;

  String? _errorMsg;

  Coordinate? errorLocation;

  Geometry? errorIndicator;

  BufferResultValidator(this.input, this.distance, this.result);

  bool isValidF() {
    checkPolygonal();
    if (!isValid) return isValid;

    checkExpectedEmpty();
    if (!isValid) {
      return isValid;
    }

    checkEnvelope();
    if (!isValid) {
      return isValid;
    }

    checkArea();
    if (!isValid) {
      return isValid;
    }

    checkDistance();
    return isValid;
  }

  String? getErrorMessage() {
    return _errorMsg;
  }

  Coordinate? getErrorLocation() {
    return errorLocation;
  }

  Geometry? getErrorIndicator() {
    return errorIndicator;
  }

  void report(String checkName) {
    if (!VERBOSE) {
      return;
    }
  }

  void checkPolygonal() {
    if (!((result is Polygon) || (result is MultiPolygon))) isValid = false;

    _errorMsg = "Result is not polygonal";
    errorIndicator = result;
    report("Polygonal");
  }

  void checkExpectedEmpty() {
    if (input.getDimension() >= 2) {
      return;
    }

    if (distance > 0.0) {
      return;
    }

    if (!result.isEmpty()) {
      isValid = false;
      _errorMsg = "Result is non-empty";
      errorIndicator = result;
    }
    report("ExpectedEmpty");
  }

  void checkEnvelope() {
    if (distance < 0.0) {
      return;
    }

    double padding = distance * _MAX_ENV_DIFF_FRAC;
    if (padding == 0.0) {
      padding = 0.001;
    }

    Envelope expectedEnv = Envelope.of2(input.getEnvelopeInternal());
    expectedEnv.expandBy(distance);
    Envelope bufEnv = Envelope.of2(result.getEnvelopeInternal());
    bufEnv.expandBy(padding);
    if (!bufEnv.contains3(expectedEnv)) {
      isValid = false;
      _errorMsg = "Buffer envelope is incorrect";
      errorIndicator = input.factory.toGeometry(bufEnv);
    }
    report("Envelope");
  }

  void checkArea() {
    double inputArea = input.getArea();
    double resultArea = result.getArea();
    if ((distance > 0.0) && (inputArea > resultArea)) {
      isValid = false;
      _errorMsg = "Area of positive buffer is smaller than input";
      errorIndicator = result;
    }
    if ((distance < 0.0) && (inputArea < resultArea)) {
      isValid = false;
      _errorMsg = "Area of negative buffer is larger than input";
      errorIndicator = result;
    }
    report("Area");
  }

  void checkDistance() {
    final distValid = BufferDistanceValidator(input, distance, result);
    if (!distValid.isValidF()) {
      isValid = false;
      _errorMsg = distValid.getErrorMessage();
      errorLocation = distValid.getErrorLocation();
      errorIndicator = distValid.getErrorIndicator();
    }
    report("Distance");
  }
}
