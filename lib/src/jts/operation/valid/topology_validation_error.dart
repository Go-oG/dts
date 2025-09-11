import 'package:dts/src/jts/geom/coordinate.dart';

class TopologyValidationError {
  static const int kError = 0;

  static const int kRepeatedPoint = 1;

  static const int kHoleOutSideShell = 2;

  static const int kNestedHoles = 3;

  static const int kDisconnectedInterior = 4;

  static const int kSelfIntersection = 5;

  static const int kRingSelfIntersection = 6;

  static const int kNestedShells = 7;

  static const int kDuplicateRings = 8;

  static const int kTooFewPoints = 9;

  static const int kInvalidCoordinate = 10;

  static const int kRingNotClosed = 11;

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
    if (_pt != null) locStr = " at or near point $_pt";

    return getMessage() + locStr;
  }
}
