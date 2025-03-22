import 'package:dts/src/jts/geom/coordinate.dart';

class TopologyValidationError {
  static const int ERROR = 0;

  static const int REPEATED_POINT = 1;

  static const int HOLE_OUTSIDE_SHELL = 2;

  static const int NESTED_HOLES = 3;

  static const int DISCONNECTED_INTERIOR = 4;

  static const int SELF_INTERSECTION = 5;

  static const int RING_SELF_INTERSECTION = 6;

  static const int NESTED_SHELLS = 7;

  static const int DUPLICATE_RINGS = 8;

  static const int TOO_FEW_POINTS = 9;

  static const int INVALID_COORDINATE = 10;

  static const int RING_NOT_CLOSED = 11;

  static final List<String> errMsg = [
    "Topology Validation Error",
    "Repeated Point",
    "Hole lies outside shell",
    "Holes are nested",
    "Interior is disconnected",
    "Self-intersection",
    "Ring Self-intersection",
    "Nested shells",
    "Duplicate Rings",
    "Too few distinct points in geometry component",
    "Invalid Coordinate",
    "Ring is not closed",
  ];

  final int _errorType;

  Coordinate? _pt;

  TopologyValidationError(this._errorType, [Coordinate? pt]) {
    if (pt != null) {
      _pt = pt.copy();
    }
  }

  Coordinate? getCoordinate() {
    return _pt;
  }

  int getErrorType() {
    return _errorType;
  }

  String getMessage() {
    return errMsg[_errorType];
  }

  @override
  String toString() {
    String locStr = "";
    if (_pt != null) locStr = " at or near point $_pt" ;

    return getMessage() + locStr;
  }
}
