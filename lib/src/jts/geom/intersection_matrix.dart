 import 'package:d_util/d_util.dart';

import 'dimension.dart';
import 'location.dart';

class IntersectionMatrix {
  late Array<Array<int>> _matrix;

  IntersectionMatrix() {
    _matrix = Array.matrix(3);
    setAll(Dimension.FALSE);
  }

  IntersectionMatrix.of(String elements) {
    _matrix = Array.matrix(3);
    setAll(Dimension.FALSE);
    set(elements);
  }

  IntersectionMatrix.of2(IntersectionMatrix other) {
    _matrix = Array.matrix(3);
    setAll(Dimension.FALSE);
    _matrix[Location.interior][Location.interior] = other._matrix[Location.interior][Location.interior];
    _matrix[Location.interior][Location.boundary] = other._matrix[Location.interior][Location.boundary];
    _matrix[Location.interior][Location.exterior] = other._matrix[Location.interior][Location.exterior];
    _matrix[Location.boundary][Location.interior] = other._matrix[Location.boundary][Location.interior];
    _matrix[Location.boundary][Location.boundary] = other._matrix[Location.boundary][Location.boundary];
    _matrix[Location.boundary][Location.exterior] = other._matrix[Location.boundary][Location.exterior];
    _matrix[Location.exterior][Location.interior] = other._matrix[Location.exterior][Location.interior];
    _matrix[Location.exterior][Location.boundary] = other._matrix[Location.exterior][Location.boundary];
    _matrix[Location.exterior][Location.exterior] = other._matrix[Location.exterior][Location.exterior];
  }

  void add(IntersectionMatrix im) {
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        setAtLeast2(i, j, im.get(i, j));
      }
    }
  }

  static bool isTrue(int actualDimensionValue) {
    if ((actualDimensionValue >= 0) || (actualDimensionValue == Dimension.TRUE)) {
      return true;
    }
    return false;
  }

  static bool matches(int actualDimensionValue, String requiredDimensionSymbol) {
    if (requiredDimensionSymbol == Dimension.SYM_DONTCARE) {
      return true;
    }
    if ((requiredDimensionSymbol == Dimension.SYM_TRUE) &&
        ((actualDimensionValue >= 0) || (actualDimensionValue == Dimension.TRUE))) {
      return true;
    }
    if ((requiredDimensionSymbol == Dimension.SYM_FALSE) && (actualDimensionValue == Dimension.FALSE)) {
      return true;
    }
    if ((requiredDimensionSymbol == Dimension.SYM_P) && (actualDimensionValue == Dimension.P)) {
      return true;
    }
    if ((requiredDimensionSymbol == Dimension.SYM_L) && (actualDimensionValue == Dimension.L)) {
      return true;
    }
    if ((requiredDimensionSymbol == Dimension.SYM_A) && (actualDimensionValue == Dimension.A)) {
      return true;
    }
    return false;
  }

  static bool matches3(String actualDimensionSymbols, String requiredDimensionSymbols) {
    IntersectionMatrix m = IntersectionMatrix.of(actualDimensionSymbols);
    return m.matches2(requiredDimensionSymbols);
  }

  void set2(int row, int column, int dimensionValue) {
    _matrix[row][column] = dimensionValue;
  }

  void set(String dimensionSymbols) {
    for (int i = 0; i < dimensionSymbols.length; i++) {
      int row = i ~/ 3;
      int col = i % 3;
      _matrix[row][col] = Dimension.toDimensionValue(dimensionSymbols.substring(i, i + 1));
    }
  }

  void setAtLeast2(int row, int column, int minimumDimensionValue) {
    if (_matrix[row][column] < minimumDimensionValue) {
      _matrix[row][column] = minimumDimensionValue;
    }
  }

  void setAtLeastIfValid(int row, int column, int minimumDimensionValue) {
    if ((row >= 0) && (column >= 0)) {
      setAtLeast2(row, column, minimumDimensionValue);
    }
  }

  void setAtLeast(String minimumDimensionSymbols) {
    for (int i = 0; i < minimumDimensionSymbols.length; i++) {
      int row = i ~/ 3;
      int col = i % 3;
      setAtLeast2(row, col, Dimension.toDimensionValue(minimumDimensionSymbols.substring(i, i + 1)));
    }
  }

  void setAll(int dimensionValue) {
    for (int ai = 0; ai < 3; ai++) {
      for (int bi = 0; bi < 3; bi++) {
        _matrix[ai][bi] = dimensionValue;
      }
    }
  }

  int get(int row, int column) {
    return _matrix[row][column];
  }

  bool isDisjoint() {
    return (((_matrix[Location.interior][Location.interior] == Dimension.FALSE) &&
                (_matrix[Location.interior][Location.boundary] == Dimension.FALSE)) &&
            (_matrix[Location.boundary][Location.interior] == Dimension.FALSE)) &&
        (_matrix[Location.boundary][Location.boundary] == Dimension.FALSE);
  }

  bool isIntersects() {
    return !isDisjoint();
  }

  bool isTouches(int dimensionOfGeometryA, int dimensionOfGeometryB) {
    if (dimensionOfGeometryA > dimensionOfGeometryB) {
      return isTouches(dimensionOfGeometryB, dimensionOfGeometryA);
    }
    if ((((((dimensionOfGeometryA == Dimension.A) && (dimensionOfGeometryB == Dimension.A)) ||
                    ((dimensionOfGeometryA == Dimension.L) && (dimensionOfGeometryB == Dimension.L))) ||
                ((dimensionOfGeometryA == Dimension.L) && (dimensionOfGeometryB == Dimension.A))) ||
            ((dimensionOfGeometryA == Dimension.P) && (dimensionOfGeometryB == Dimension.A))) ||
        ((dimensionOfGeometryA == Dimension.P) && (dimensionOfGeometryB == Dimension.L))) {
      return (_matrix[Location.interior][Location.interior] == Dimension.FALSE) &&
          ((isTrue(_matrix[Location.interior][Location.boundary]) ||
                  isTrue(_matrix[Location.boundary][Location.interior])) ||
              isTrue(_matrix[Location.boundary][Location.boundary]));
    }
    return false;
  }

  bool isCrosses(int dimensionOfGeometryA, int dimensionOfGeometryB) {
    if ((((dimensionOfGeometryA == Dimension.P) && (dimensionOfGeometryB == Dimension.L)) ||
            ((dimensionOfGeometryA == Dimension.P) && (dimensionOfGeometryB == Dimension.A))) ||
        ((dimensionOfGeometryA == Dimension.L) && (dimensionOfGeometryB == Dimension.A))) {
      return isTrue(_matrix[Location.interior][Location.interior]) &&
          isTrue(_matrix[Location.interior][Location.exterior]);
    }
    if ((((dimensionOfGeometryA == Dimension.L) && (dimensionOfGeometryB == Dimension.P)) ||
            ((dimensionOfGeometryA == Dimension.A) && (dimensionOfGeometryB == Dimension.P))) ||
        ((dimensionOfGeometryA == Dimension.A) && (dimensionOfGeometryB == Dimension.L))) {
      return isTrue(_matrix[Location.interior][Location.interior]) &&
          isTrue(_matrix[Location.exterior][Location.interior]);
    }
    if ((dimensionOfGeometryA == Dimension.L) && (dimensionOfGeometryB == Dimension.L)) {
      return _matrix[Location.interior][Location.interior] == 0;
    }
    return false;
  }

  bool isWithin() {
    return (isTrue(_matrix[Location.interior][Location.interior]) &&
            (_matrix[Location.interior][Location.exterior] == Dimension.FALSE)) &&
        (_matrix[Location.boundary][Location.exterior] == Dimension.FALSE);
  }

  bool isContains() {
    return (isTrue(_matrix[Location.interior][Location.interior]) &&
            (_matrix[Location.exterior][Location.interior] == Dimension.FALSE)) &&
        (_matrix[Location.exterior][Location.boundary] == Dimension.FALSE);
  }

  bool isCovers() {
    bool hasPointInCommon =
        ((isTrue(_matrix[Location.interior][Location.interior]) ||
                isTrue(_matrix[Location.interior][Location.boundary])) ||
            isTrue(_matrix[Location.boundary][Location.interior])) ||
        isTrue(_matrix[Location.boundary][Location.boundary]);
    return (hasPointInCommon && (_matrix[Location.exterior][Location.interior] == Dimension.FALSE)) &&
        (_matrix[Location.exterior][Location.boundary] == Dimension.FALSE);
  }

  bool isCoveredBy() {
    bool hasPointInCommon =
        ((isTrue(_matrix[Location.interior][Location.interior]) ||
                isTrue(_matrix[Location.interior][Location.boundary])) ||
            isTrue(_matrix[Location.boundary][Location.interior])) ||
        isTrue(_matrix[Location.boundary][Location.boundary]);
    return (hasPointInCommon && (_matrix[Location.interior][Location.exterior] == Dimension.FALSE)) &&
        (_matrix[Location.boundary][Location.exterior] == Dimension.FALSE);
  }

  bool isEquals(int dimensionOfGeometryA, int dimensionOfGeometryB) {
    if (dimensionOfGeometryA != dimensionOfGeometryB) {
      return false;
    }
    return (((isTrue(_matrix[Location.interior][Location.interior]) &&
                    (_matrix[Location.interior][Location.exterior] == Dimension.FALSE)) &&
                (_matrix[Location.boundary][Location.exterior] == Dimension.FALSE)) &&
            (_matrix[Location.exterior][Location.interior] == Dimension.FALSE)) &&
        (_matrix[Location.exterior][Location.boundary] == Dimension.FALSE);
  }

  bool isOverlaps(int dimensionOfGeometryA, int dimensionOfGeometryB) {
    if (((dimensionOfGeometryA == Dimension.P) && (dimensionOfGeometryB == Dimension.P)) ||
        ((dimensionOfGeometryA == Dimension.A) && (dimensionOfGeometryB == Dimension.A))) {
      return (isTrue(_matrix[Location.interior][Location.interior]) &&
              isTrue(_matrix[Location.interior][Location.exterior])) &&
          isTrue(_matrix[Location.exterior][Location.interior]);
    }
    if ((dimensionOfGeometryA == Dimension.L) && (dimensionOfGeometryB == Dimension.L)) {
      return ((_matrix[Location.interior][Location.interior] == 1) &&
              isTrue(_matrix[Location.interior][Location.exterior])) &&
          isTrue(_matrix[Location.exterior][Location.interior]);
    }
    return false;
  }

  bool matches2(String pattern) {
    if (pattern.length != 9) {
      throw IllegalArgumentException("Should be length 9: $pattern");
    }
    for (int ai = 0; ai < 3; ai++) {
      for (int bi = 0; bi < 3; bi++) {
        if (!matches(_matrix[ai][bi], pattern.substring((3 * ai) + bi, ((3 * ai) + bi) + 1))) {
          return false;
        }
      }
    }
    return true;
  }

  IntersectionMatrix transpose() {
    int temp = _matrix[1][0];
    _matrix[1][0] = _matrix[0][1];
    _matrix[0][1] = temp;
    temp = _matrix[2][0];
    _matrix[2][0] = _matrix[0][2];
    _matrix[0][2] = temp;
    temp = _matrix[2][1];
    _matrix[2][1] = _matrix[1][2];
    _matrix[1][2] = temp;
    return this;
  }
}
