import 'package:dts/src/jts/geom/dimension.dart';

class EdgeSourceInfo {
  int index;

  int _dim = -999;

  bool _isHole = false;

  int depthDelta = 0;

  EdgeSourceInfo(this.index, this.depthDelta, this._isHole) {
    _dim = Dimension.A;
  }

  EdgeSourceInfo.of(this.index) {
    _dim = Dimension.L;
  }

  int getIndex() {
    return index;
  }

  int getDimension() {
    return _dim;
  }

  int getDepthDelta() {
    return depthDelta;
  }

  bool isHole() {
    return _isHole;
  }
}
