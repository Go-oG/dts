import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/location.dart';

class DimensionLocation {
  static const int EXTERIOR = Location.exterior;

  static const int POINT_INTERIOR = 103;

  static const int LINE_INTERIOR = 110;

  static const int LINE_BOUNDARY = 111;

  static const int AREA_INTERIOR = 120;

  static const int AREA_BOUNDARY = 121;

  static int locationArea(int loc) {
    switch (loc) {
      case Location.interior:
        return AREA_INTERIOR;
      case Location.boundary:
        return AREA_BOUNDARY;
    }
    return EXTERIOR;
  }

  static int locationLine(int loc) {
    switch (loc) {
      case Location.interior:
        return LINE_INTERIOR;
      case Location.boundary:
        return LINE_BOUNDARY;
    }
    return EXTERIOR;
  }

  static int locationPoint(int loc) {
    switch (loc) {
      case Location.interior:
        return POINT_INTERIOR;
    }
    return EXTERIOR;
  }

  static int location(int dimLoc) {
    switch (dimLoc) {
      case POINT_INTERIOR:
      case LINE_INTERIOR:
      case AREA_INTERIOR:
        return Location.interior;
      case LINE_BOUNDARY:
      case AREA_BOUNDARY:
        return Location.boundary;
    }
    return Location.exterior;
  }

  static int dimension(int dimLoc) {
    switch (dimLoc) {
      case POINT_INTERIOR:
        return Dimension.P;
      case LINE_INTERIOR:
      case LINE_BOUNDARY:
        return Dimension.L;
      case AREA_INTERIOR:
      case AREA_BOUNDARY:
        return Dimension.A;
    }
    return Dimension.False;
  }

  static int dimension2(int dimLoc, int exteriorDim) {
    if (dimLoc == EXTERIOR) {
      return exteriorDim;
    }

    return dimension(dimLoc);
  }
}
