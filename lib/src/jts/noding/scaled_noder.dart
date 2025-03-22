 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';

import 'noded_segment_string.dart';
import 'noder.dart';
import 'segment_string.dart';

class ScaledNoder implements Noder {
  final Noder _noder;

  double scaleFactor;

  double _offsetX = 0;

  double _offsetY = 0;

  bool _isScaled = false;

  ScaledNoder(this._noder, this.scaleFactor, [double offsetX = 0, double offsetY = 0]) {
    _isScaled = !isIntegerPrecision();
    _offsetX = offsetX;
    _offsetY = offsetY;
  }

  bool isIntegerPrecision() {
    return scaleFactor == 1.0;
  }

  @override
  List<SegmentString>? getNodedSubstrings() {
    List<SegmentString>? splitSS = _noder.getNodedSubstrings();
    if (_isScaled) {
      rescale(splitSS!);
    }
    return splitSS;
  }

  @override
  void computeNodes(List<SegmentString> inputSegStrings) {
    List<SegmentString> intSegStrings = inputSegStrings;
    if (_isScaled) {
      intSegStrings = scale(inputSegStrings);
    }
    _noder.computeNodes(intSegStrings);
  }

  List<SegmentString> scale(List<SegmentString> segStrings) {
    List<SegmentString> nodedSegmentStrings = [];
    for (var ss in segStrings) {
      nodedSegmentStrings.add(NodedSegmentString(scale2(ss.getCoordinates()), ss.getData()));
    }
    return nodedSegmentStrings;
  }

  Array<Coordinate> scale2(Array<Coordinate> pts) {
    Array<Coordinate> roundPts = Array(pts.length);
    for (int i = 0; i < pts.length; i++) {
      roundPts[i] = Coordinate(
        Math.round((pts[i].x - _offsetX) * scaleFactor).toDouble(),
        Math.round((pts[i].y - _offsetY) * scaleFactor).toDouble(),
        pts[i].getZ(),
      );
    }
    Array<Coordinate> roundPtsNoDup = CoordinateArrays.removeRepeatedPoints(roundPts);
    return roundPtsNoDup;
  }

  void rescale(List<SegmentString> segStrings) {
    for (var ss in segStrings) {
      rescale2(ss.getCoordinates());
    }
  }

  void rescale2(Array<Coordinate> pts) {
    for (int i = 0; i < pts.length; i++) {
      pts[i].x = (pts[i].x / scaleFactor) + _offsetX;
      pts[i].y = (pts[i].y / scaleFactor) + _offsetY;
    }
  }
}
