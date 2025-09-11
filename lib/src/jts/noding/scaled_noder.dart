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

  ScaledNoder(this._noder, this.scaleFactor,
      [double offsetX = 0, double offsetY = 0]) {
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
      nodedSegmentStrings.add(
          NodedSegmentString(scaleArray(ss.getCoordinates()), ss.getData()));
    }
    return nodedSegmentStrings;
  }

  List<Coordinate> scaleArray(List<Coordinate> pts) {
    List<Coordinate> roundPts = [];
    for (int i = 0; i < pts.length; i++) {
      roundPts.add(Coordinate(
        ((pts[i].x - _offsetX) * scaleFactor).roundToDouble(),
        ((pts[i].y - _offsetY) * scaleFactor).roundToDouble(),
        pts[i].z,
      ));
    }
    return CoordinateArrays.removeRepeatedPoints(roundPts);
  }

  void rescale(List<SegmentString> segStrings) {
    for (var ss in segStrings) {
      rescaleArray(ss.getCoordinates());
    }
  }

  void rescaleArray(List<Coordinate> pts) {
    for (int i = 0; i < pts.length; i++) {
      pts[i].x = (pts[i].x / scaleFactor) + _offsetX;
      pts[i].y = (pts[i].y / scaleFactor) + _offsetY;
    }
  }
}
