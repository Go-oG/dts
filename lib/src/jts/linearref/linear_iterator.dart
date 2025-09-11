import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/lineal.dart';

import 'linear_location.dart';

class LinearIterator {
  static int segmentEndVertexIndex(LinearLocation loc) {
    if (loc.getSegmentFraction() > 0.0) return loc.getSegmentIndex() + 1;

    return loc.getSegmentIndex();
  }

  Geometry linearGeom;

  late final int _numLines;

  LineString? _currentLine;

  int _componentIndex = 0;

  int _vertexIndex = 0;

  LinearIterator(this.linearGeom, this._componentIndex, this._vertexIndex) {
    if (linearGeom is! Lineal) {
      throw ("Lineal geometry is required");
    }
    _numLines = linearGeom.getNumGeometries();
    loadCurrentLine();
  }

  LinearIterator.of(Geometry linear) : this(linear, 0, 0);

  LinearIterator.of2(Geometry linear, LinearLocation start)
      : this(linear, start.getComponentIndex(), segmentEndVertexIndex(start));

  void loadCurrentLine() {
    if (_componentIndex >= _numLines) {
      _currentLine = null;
      return;
    }
    _currentLine = linearGeom.getGeometryN(_componentIndex) as LineString;
  }

  bool hasNext() {
    if (_componentIndex >= _numLines) return false;

    if ((_componentIndex == (_numLines - 1)) &&
        (_vertexIndex >= _currentLine!.getNumPoints())) {
      return false;
    }

    return true;
  }

  void next() {
    if (!hasNext()) return;

    _vertexIndex++;
    if (_vertexIndex >= _currentLine!.getNumPoints()) {
      _componentIndex++;
      loadCurrentLine();
      _vertexIndex = 0;
    }
  }

  bool isEndOfLine() {
    if (_componentIndex >= _numLines) return false;

    if (_vertexIndex < (_currentLine!.getNumPoints() - 1)) return false;

    return true;
  }

  int getComponentIndex() {
    return _componentIndex;
  }

  int getVertexIndex() {
    return _vertexIndex;
  }

  LineString? getLine() {
    return _currentLine;
  }

  Coordinate getSegmentStart() {
    return _currentLine!.getCoordinateN(_vertexIndex);
  }

  Coordinate? getSegmentEnd() {
    if (_vertexIndex < (getLine()!.getNumPoints() - 1)) {
      return _currentLine!.getCoordinateN(_vertexIndex + 1);
    }

    return null;
  }
}
