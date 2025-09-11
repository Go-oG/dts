import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/operation/overlay/overlay_op.dart';
import 'package:dts/src/jts/operation/overlay/snap/geometry_snapper.dart';

import 'fuzzy_point_locator.dart';
import 'offset_point_generator.dart';

class OverlayResultValidator {
  static bool isValid2(Geometry a, Geometry b, OverlayOpCode overlayOp, Geometry result) {
    return OverlayResultValidator(a, b, result).isValid(overlayOp);
  }

  static double computeBoundaryDistanceTolerance(Geometry g0, Geometry g1) {
    return Math.minD(
      GeometrySnapper.computeSizeBasedSnapTolerance(g0),
      GeometrySnapper.computeSizeBasedSnapTolerance(g1),
    );
  }

  static const double _kTolerance = 1.0E-6;

  late Array<Geometry> geom;

  late Array<FuzzyPointLocator> _locFinder;

  final Array<int> _location = Array(3);

  Coordinate? _invalidLocation;

  double _boundaryDistanceTolerance = _kTolerance;

  final List<Coordinate> _testCoords = [];

  OverlayResultValidator(Geometry a, Geometry b, Geometry result) {
    _boundaryDistanceTolerance = computeBoundaryDistanceTolerance(a, b);
    geom = [a, b, result].toArray();
    _locFinder = [
      FuzzyPointLocator(geom[0], _boundaryDistanceTolerance),
      FuzzyPointLocator(geom[1], _boundaryDistanceTolerance),
      FuzzyPointLocator(geom[2], _boundaryDistanceTolerance),
    ].toArray();
  }

  bool isValid(OverlayOpCode overlayOp) {
    addTestPts(geom[0]);
    addTestPts(geom[1]);
    bool isValid = checkValid(overlayOp);
    return isValid;
  }

  Coordinate? getInvalidLocation() {
    return _invalidLocation;
  }

  void addTestPts(Geometry g) {
    final ptGen = OffsetPointGenerator(g);
    _testCoords.addAll(ptGen.getPoints(5 * _boundaryDistanceTolerance));
  }

  bool checkValid(OverlayOpCode overlayOp) {
    for (int i = 0; i < _testCoords.size; i++) {
      Coordinate pt = _testCoords.get(i);
      if (!checkValid2(overlayOp, pt)) {
        _invalidLocation = pt;
        return false;
      }
    }
    return true;
  }

  bool checkValid2(OverlayOpCode overlayOp, Coordinate pt) {
    _location[0] = _locFinder[0].getLocation(pt);
    _location[1] = _locFinder[1].getLocation(pt);
    _location[2] = _locFinder[2].getLocation(pt);
    if (hasLocation(_location, Location.boundary)) return true;

    return isValidResult(overlayOp, _location);
  }

  static bool hasLocation(Array<int> location, int loc) {
    for (int i = 0; i < 3; i++) {
      if (location[i] == loc) return true;
    }
    return false;
  }

  bool isValidResult(OverlayOpCode overlayOp, Array<int> location) {
    bool expectedInterior = OverlayOp.isResultOfOp2(location[0], location[1], overlayOp);
    bool resultInInterior = location[2] == Location.interior;
    return !(expectedInterior ^ resultInInterior);
  }
}
