import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/position.dart';

import 'label.dart';

class Depth {
  static const int _kNullValue = -1;

  static int depthAtLocation(int location) {
    if (location == Location.exterior) {
      return 0;
    }

    if (location == Location.interior) {
      return 1;
    }

    return _kNullValue;
  }

  final List<List<int>> _depth = List.generate(2, (i) => List.filled(3, 0));

  Depth() {
    for (int i = 0; i < 2; i++) {
      for (int j = 0; j < 3; j++) {
        _depth[i][j] = _kNullValue;
      }
    }
  }

  int getDepth(int geomIndex, int posIndex) {
    return _depth[geomIndex][posIndex];
  }

  void setDepth(int geomIndex, int posIndex, int depthValue) {
    _depth[geomIndex][posIndex] = depthValue;
  }

  int getLocation(int geomIndex, int posIndex) {
    if (_depth[geomIndex][posIndex] <= 0) {
      return Location.exterior;
    }

    return Location.interior;
  }

  void add(int geomIndex, int posIndex, int location) {
    if (location == Location.interior) {
      _depth[geomIndex][posIndex]++;
    }
  }

  bool isNull() {
    for (int i = 0; i < 2; i++) {
      for (int j = 0; j < 3; j++) {
        if (_depth[i][j] != _kNullValue) {
          return false;
        }
      }
    }
    return true;
  }

  bool isNull2(int geomIndex) {
    return _depth[geomIndex][1] == _kNullValue;
  }

  bool isNull3(int geomIndex, int posIndex) {
    return _depth[geomIndex][posIndex] == _kNullValue;
  }

  void addLabel(Label lbl) {
    for (int i = 0; i < 2; i++) {
      for (int j = 1; j < 3; j++) {
        int loc = lbl.getLocation2(i, j);
        if ((loc == Location.exterior) || (loc == Location.interior)) {
          if (isNull3(i, j)) {
            _depth[i][j] = depthAtLocation(loc);
          } else {
            _depth[i][j] += depthAtLocation(loc);
          }
        }
      }
    }
  }

  int getDelta(int geomIndex) {
    return _depth[geomIndex][Position.right] - _depth[geomIndex][Position.left];
  }

  void normalize() {
    for (int i = 0; i < 2; i++) {
      if (!isNull2(i)) {
        int minDepth = _depth[i][1];
        if (_depth[i][2] < minDepth) {
          minDepth = _depth[i][2];
        }

        if (minDepth < 0) {
          minDepth = 0;
        }

        for (int j = 1; j < 3; j++) {
          int newValue = 0;
          if (_depth[i][j] > minDepth) {
            newValue = 1;
          }

          _depth[i][j] = newValue;
        }
      }
    }
  }
}
