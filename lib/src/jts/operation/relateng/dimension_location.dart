import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/location.dart';

class DimensionLocation {
  static const int kExterior = Location.exterior;

  static const int kPointInterior = 103;

  static const int kLineInterior = 110;

  static const int kLineBoundary = 111;

  static const int kAreaInterior = 120;

  static const int kAreaBoundary = 121;

  static int locationArea(int loc) {
    switch (loc) {
      case Location.interior:
        return kAreaInterior;
      case Location.boundary:
        return kAreaBoundary;
    }
    return kExterior;
  }

  static int locationLine(int loc) {
    switch (loc) {
      case Location.interior:
        return kLineInterior;
      case Location.boundary:
        return kLineBoundary;
    }
    return kExterior;
  }

  static int locationPoint(int loc) {
    switch (loc) {
      case Location.interior:
        return kPointInterior;
    }
    return kExterior;
  }

  static int location(int dimLoc) {
    switch (dimLoc) {
      case kPointInterior:
      case kLineInterior:
      case kAreaInterior:
        return Location.interior;
      case kLineBoundary:
      case kAreaBoundary:
        return Location.boundary;
    }
    return Location.exterior;
  }

  static int dimension(int dimLoc) {
    switch (dimLoc) {
      case kPointInterior:
        return Dimension.P;
      case kLineInterior:
      case kLineBoundary:
        return Dimension.L;
      case kAreaInterior:
      case kAreaBoundary:
        return Dimension.A;
    }
    return Dimension.kFalse;
  }

  static int dimension2(int dimLoc, int exteriorDim) {
    if (dimLoc == kExterior) {
      return exteriorDim;
    }

    return dimension(dimLoc);
  }
}
