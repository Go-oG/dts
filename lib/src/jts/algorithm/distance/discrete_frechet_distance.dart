import 'dart:math' as m;

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/distance/point_pair_distance.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/util/collection_util.dart';

class DiscreteFrechetDistance {
  static double distance(Geometry g0, Geometry g1) {
    return DiscreteFrechetDistance(g0, g1)._distance();
  }

  final Geometry _g0;

  final Geometry _g1;

  late final PointPairDistance _ptDist;

  DiscreteFrechetDistance(this._g0, this._g1);

  double _distance() {
    final coords0 = _g0.getCoordinates();
    final coords1 = _g1.getCoordinates();
    MatrixStorage distances =
        _createMatrixStorage(coords0.length, coords1.length);
    List<int> diagonal = bresenhamDiagonal(coords0.length, coords1.length);
    Map<double, List<int>> distanceToPair = {};
    _computeCoordinateDistances(
        coords0, coords1, diagonal, distances, distanceToPair);
    _ptDist =
        _computeFrechet(coords0, coords1, diagonal, distances, distanceToPair);
    return _ptDist.getDistance();
  }

  static MatrixStorage _createMatrixStorage(int rows, int cols) {
    int max = m.max(rows, cols);
    if (max < 1024) {
      return RectMatrix(rows, cols, double.infinity);
    }

    return CsrMatrix.of(rows, cols, double.infinity);
  }

  bool _init = false;
  List<Coordinate> getCoordinates() {
    if (_init == false) {
      _init = true;
      _distance();
    }
    return _ptDist.getCoordinates();
  }

  static PointPairDistance _computeFrechet(
    List<Coordinate> coords0,
    List<Coordinate> coords1,
    List<int> diagonal,
    MatrixStorage distances,
    Map<double, List<int>> distanceToPair,
  ) {
    for (int d = 0; d < diagonal.length; d += 2) {
      int i0 = diagonal[d];
      int j0 = diagonal[d + 1];
      for (int i = i0; i < coords0.length; i++) {
        if (distances.isValueSet(i, j0)) {
          double dist = _getMinDistanceAtCorner(distances, i, j0);
          if (dist > distances.get(i, j0)) {
            distances.set(i, j0, dist);
          }
        } else {
          break;
        }
      }
      for (int j = j0 + 1; j < coords1.length; j++) {
        if (distances.isValueSet(i0, j)) {
          double dist = _getMinDistanceAtCorner(distances, i0, j);
          if (dist > distances.get(i0, j)) {
            distances.set(i0, j, dist);
          }
        } else {
          break;
        }
      }
    }
    PointPairDistance result = PointPairDistance();
    double distance = distances.get(coords0.length - 1, coords1.length - 1);
    List<int>? index = distanceToPair[distance];
    if (index == null) {
      throw ("Pair of points not recorded for computed distance");
    }
    result.initialize3(coords0[index[0]], coords1[index[1]], distance);
    return result;
  }

  static double _getMinDistanceAtCorner(MatrixStorage matrix, int i, int j) {
    if ((i > 0) && (j > 0)) {
      double d0 = matrix.get(i - 1, j - 1);
      double d1 = matrix.get(i - 1, j);
      double d2 = matrix.get(i, j - 1);
      return m.min(m.min(d0, d1), d2);
    }
    if ((i == 0) && (j == 0)) {
      return matrix.get(0, 0);
    }

    if (i == 0) {
      return matrix.get(0, j - 1);
    }

    return matrix.get(i - 1, 0);
  }

  void _computeCoordinateDistances(
    List<Coordinate> coords0,
    List<Coordinate> coords1,
    List<int> diagonal,
    MatrixStorage distances,
    Map<double, List<int>> distanceToPair,
  ) {
    int numDiag = diagonal.length;
    double maxDistOnDiag = 0.0;
    int imin = 0;
    int jmin = 0;
    int numCoords0 = coords0.length;
    int numCoords1 = coords1.length;
    for (int k = 0; k < numDiag; k += 2) {
      int i0 = diagonal[k];
      int j0 = diagonal[k + 1];
      double diagDist = coords0[i0].distance(coords1[j0]);
      if (diagDist > maxDistOnDiag) {
        maxDistOnDiag = diagDist;
      }

      distances.set(i0, j0, diagDist);
      distanceToPair.putIfAbsent(diagDist, () => [i0, j0]);
    }
    for (int k = 0; k < (numDiag - 2); k += 2) {
      int i0 = diagonal[k];
      int j0 = diagonal[k + 1];
      Coordinate coord0 = coords0[i0];
      Coordinate coord1 = coords1[j0];
      int i = i0 + 1;
      for (; i < numCoords0; i++) {
        if (!distances.isValueSet(i, j0)) {
          double dist = coords0[i].distance(coord1);
          if ((dist < maxDistOnDiag) || (i < imin)) {
            distances.set(i, j0, dist);
            distanceToPair.putIfAbsent(dist, () => [i, j0]);
          } else {
            break;
          }
        } else {
          break;
        }
      }
      imin = i;
      int j = j0 + 1;
      for (; j < numCoords1; j++) {
        if (!distances.isValueSet(i0, j)) {
          double dist = coord0.distance(coords1[j]);
          if ((dist < maxDistOnDiag) || (j < jmin)) {
            distances.set(i0, j, dist);
            distanceToPair.putIfAbsent(dist, () => [i0, j]);
          } else {
            break;
          }
        } else {
          break;
        }
      }
      jmin = j;
    }
  }

  static List<int> bresenhamDiagonal(int numCols, int numRows) {
    int dim = m.max(numCols, numRows).toInt();
    List<int> diagXY = List.filled(2 * dim, 0);
    int dx = numCols - 1;
    int dy = numRows - 1;
    int err;
    int i = 0;
    if (numCols > numRows) {
      int y = 0;
      err = (2 * dy) - dx;
      for (int x = 0; x < numCols; x++) {
        diagXY[i++] = x;
        diagXY[i++] = y;
        if (err > 0) {
          y += 1;
          err -= 2 * dx;
        }
        err += 2 * dy;
      }
    } else {
      int x = 0;
      err = (2 * dx) - dy;
      for (int y = 0; y < numRows; y++) {
        diagXY[i++] = x;
        diagXY[i++] = y;
        if (err > 0) {
          x += 1;
          err -= 2 * dy;
        }
        err += 2 * dx;
      }
    }
    return diagXY;
  }
}

abstract class MatrixStorage {
  final int numRows;

  final int numCols;

  final double defaultValue;

  MatrixStorage(this.numRows, this.numCols, this.defaultValue);

  double get(int i, int j);

  void set(int i, int j, double value);

  bool isValueSet(int i, int j);
}

final class RectMatrix extends MatrixStorage {
  late final List<double> matrix;

  RectMatrix(super.numRows, super.numCols, super.defaultValue) {
    matrix = List.filled(numRows * numCols, 0);
    for (var i = 0; i < matrix.length; i++) {
      matrix[i] = defaultValue;
    }
  }

  @override
  double get(int i, int j) {
    return matrix[(i * numCols) + j];
  }

  @override
  void set(int i, int j, double value) {
    matrix[(i * numCols) + j] = value;
  }

  @override
  bool isValueSet(int i, int j) {
    return Double.doubleToLongBits(get(i, j)) !=
        Double.doubleToLongBits(defaultValue);
  }
}

final class CsrMatrix extends MatrixStorage {
  late List<double> v;
  late final List<int> ri;
  late List<int> ci;

  static CsrMatrix of(int numRows, int numCols, double defaultValue) {
    return CsrMatrix(numRows, numCols, defaultValue,
        expectedValuesHeuristic(numRows, numCols));
  }

  CsrMatrix(
      super.numRows, super.numCols, super.defaultValue, int expectedValues) {
    v = List.filled(expectedValues, 0);
    ci = List.filled(expectedValues, 0);
    ri = List.filled(numRows + 1, 0);
  }

  static int expectedValuesHeuristic(int numRows, int numCols) {
    int max = m.max(numRows, numCols).toInt();
    return (max * max) ~/ 10;
  }

  int indexOf(int i, int j) {
    int cLow = ri[i];
    int cHigh = ri[i + 1];
    if (cHigh <= cLow) {
      return ~cLow;
    }
    return CollectionUtil.binarySearch(ci, cLow, cHigh, j);
  }

  @override
  double get(int i, int j) {
    int vi = indexOf(i, j);
    if (vi < 0) {
      return defaultValue;
    }

    return v[vi];
  }

  @override
  void set(int i, int j, double value) {
    int vi = indexOf(i, j);
    if (vi < 0) {
      ensureCapacity(ri[numRows] + 1);
      for (int ii = i + 1; ii <= numRows; ii++) {
        ri[ii] += 1;
      }

      vi = ~vi;
      for (int ii = ri[numRows]; ii > vi; ii--) {
        ci[ii] = ci[ii - 1];
        v[ii] = v[ii - 1];
      }
      ci[vi] = j;
    }
    v[vi] = value;
  }

  @override
  bool isValueSet(int i, int j) {
    return indexOf(i, j) >= 0;
  }

  void ensureCapacity(int required) {
    if (required < v.length) {
      return;
    }

    int increment = m.max(numRows, numCols);

    v = CollectionUtil.copyOf(v, v.length + increment, 0);
    ci = CollectionUtil.copyOf(ci, v.length + increment, 0);
  }
}

final class HashMapMatrix extends MatrixStorage {
  late final Map<int, double> matrix = {};

  HashMapMatrix(super.numRows, super.numCols, super.defaultValue);

  @override
  double get(int i, int j) {
    int key = ((i) << 32) | j;
    return matrix[key] ?? defaultValue;
  }

  @override
  void set(int i, int j, double value) {
    int key = (i << 32) | j;
    matrix[key] = value;
  }

  @override
  bool isValueSet(int i, int j) {
    int key = ((i) << 32) | j;
    return matrix.containsKey(key);
  }
}
