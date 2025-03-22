 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/distance.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';

class BufferInputLineSimplifier {
  static Array<Coordinate> simplify2(Array<Coordinate> inputLine, double distanceTol) {
    BufferInputLineSimplifier simp = BufferInputLineSimplifier(inputLine);
    return simp.simplify(distanceTol);
  }

  static const int _DELETE = 1;

  final Array<Coordinate> _inputLine;

  double distanceTol = 0;

  bool _isRing = false;

  late Array<bool> _isDeleted;

  int _angleOrientation = Orientation.counterClockwise;

  BufferInputLineSimplifier(this._inputLine) {
    _isRing = CoordinateArrays.isRing(_inputLine);
  }

  Array<Coordinate> simplify(double distanceTol) {
    this.distanceTol = Math.abs(distanceTol);
    _angleOrientation = Orientation.counterClockwise;
    if (distanceTol < 0) {
      _angleOrientation = Orientation.clockwise;
    }

    _isDeleted = Array()[_inputLine.length];
    bool isChanged = false;
    do {
      isChanged = deleteShallowConcavities();
    } while (isChanged);
    return collapseLine();
  }

  bool deleteShallowConcavities() {
    int index = (_isRing) ? 0 : 1;
    int midIndex = nextIndex(index);
    int lastIndex = nextIndex(midIndex);
    bool isChanged = false;
    while (lastIndex < _inputLine.length) {
      bool isMiddleVertexDeleted = false;
      if (isDeletable(index, midIndex, lastIndex, distanceTol)) {
        _isDeleted[midIndex] = true;
        isMiddleVertexDeleted = true;
        isChanged = true;
      }
      if (isMiddleVertexDeleted) {
        index = lastIndex;
      } else {
        index = midIndex;
      }

      midIndex = nextIndex(index);
      lastIndex = nextIndex(midIndex);
    }
    return isChanged;
  }

  int nextIndex(int index) {
    int next = index + 1;
    while ((next < _inputLine.length) && _isDeleted[next]) {
      next++;
    }

    return next;
  }

  Array<Coordinate> collapseLine() {
    CoordinateList coordList = CoordinateList();
    for (int i = 0; i < _inputLine.length; i++) {
      if (!_isDeleted[i]) {
        coordList.add(_inputLine[i]);
      }
    }
    return coordList.toCoordinateArray();
  }

  bool isDeletable(int i0, int i1, int i2, double distanceTol) {
    Coordinate p0 = _inputLine[i0];
    Coordinate p1 = _inputLine[i1];
    Coordinate p2 = _inputLine[i2];
    if (!isConcave(p0, p1, p2)) {
      return false;
    }

    if (!isShallow(p0, p1, p2, distanceTol)) {
      return false;
    }

    return isShallowSampled(p0, p1, i0, i2, distanceTol);
  }

  static const int _NUM_PTS_TO_CHECK = 10;

  bool isShallowSampled(Coordinate p0, Coordinate p2, int i0, int i2, double distanceTol) {
    int inc = (i2 - i0) ~/ _NUM_PTS_TO_CHECK;
    if (inc <= 0) {
      inc = 1;
    }

    for (int i = i0; i < i2; i += inc) {
      if (!isShallow(p0, _inputLine[i], p2, distanceTol)) {
        return false;
      }
    }
    return true;
  }

  static bool isShallow(Coordinate p0, Coordinate p1, Coordinate p2, double distanceTol) {
    double dist = Distance.pointToSegment(p1, p0, p2);
    return dist < distanceTol;
  }

  bool isConcave(Coordinate p0, Coordinate p1, Coordinate p2) {
    int orientation = Orientation.index(p0, p1, p2);
    bool isConcave = orientation == _angleOrientation;
    return isConcave;
  }
}
