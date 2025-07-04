import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/math/math.dart';

import 'coordinate.dart';
import 'coordinate_list.dart';
import 'envelope.dart';

class CoordinateArrays {
  static int dimension(Array<Coordinate>? pts) {
    if ((pts == null) || (pts.isEmpty)) {
      return 3;
    }

    int dimension = 0;
    for (var coordinate in pts) {
      dimension = Math.max(dimension, Coordinates.dimension(coordinate)).toInt();
    }
    return dimension;
  }

  static int measures(Array<Coordinate>? pts) {
    if ((pts == null) || (pts.isEmpty)) {
      return 0;
    }
    int measures = 0;
    for (var coordinate in pts) {
      measures = Math.max(measures, Coordinates.measures(coordinate)).toInt();
    }
    return measures;
  }

  static void enforceConsistency(Array<Coordinate?>? array) {
    if (array == null) {
      return;
    }
    int maxDimension = -1;
    int maxMeasures = -1;
    bool isConsistent = true;
    for (int i = 0; i < array.length; i++) {
      Coordinate? coordinate = array[i];
      if (coordinate != null) {
        int d = Coordinates.dimension(coordinate);
        int m = Coordinates.measures(coordinate);
        if (maxDimension == (-1)) {
          maxDimension = d;
          maxMeasures = m;
          continue;
        }
        if ((d != maxDimension) || (m != maxMeasures)) {
          isConsistent = false;
          maxDimension = Math.max(maxDimension, d).toInt();
          maxMeasures = Math.max(maxMeasures, m).toInt();
        }
      }
    }
    if (!isConsistent) {
      Coordinate sample = Coordinates.createWithMeasure(maxDimension, maxMeasures);
      Type type = sample.runtimeType;
      for (int i = 0; i < array.length; i++) {
        Coordinate? coordinate = array[i];
        if ((coordinate != null) && (coordinate.runtimeType != type)) {
          Coordinate duplicate = Coordinates.createWithMeasure(maxDimension, maxMeasures);
          duplicate.setCoordinate(coordinate);
          array[i] = duplicate;
        }
      }
    }
  }

  static Array<Coordinate?> enforceConsistency2(
      Array<Coordinate?> array, int dimension, int measures) {
    Coordinate sample = Coordinates.createWithMeasure(dimension, measures);
    Type type = sample.runtimeType;
    bool isConsistent = true;
    for (int i = 0; i < array.length; i++) {
      Coordinate? coordinate = array[i];
      if ((coordinate != null) && (coordinate.runtimeType != type)) {
        isConsistent = false;
        break;
      }
    }

    if (isConsistent) {
      return array;
    } else {
      Array<Coordinate?> copy = Array(array.length);
      for (int i = 0; i < copy.length; i++) {
        Coordinate? coordinate = array[i];
        if ((coordinate != null) && (coordinate.runtimeType != type)) {
          Coordinate duplicate = Coordinates.createWithMeasure(dimension, measures);
          duplicate.setCoordinate(coordinate);
          copy[i] = duplicate;
        } else {
          copy[i] = coordinate;
        }
      }
      return copy;
    }
  }

  static bool isRing(Array<Coordinate> pts) {
    if (pts.length < 4) return false;

    if (!pts[0].equals2D(pts[pts.length - 1])) return false;

    return true;
  }

  static Coordinate? ptNotInList(Array<Coordinate> testPts, Array<Coordinate> pts) {
    for (int i = 0; i < testPts.length; i++) {
      Coordinate testPt = testPts[i];
      if (CoordinateArrays.indexOf(testPt, pts) < 0) return testPt;
    }
    return null;
  }

  static int compare(Array<Coordinate> pts1, Array<Coordinate> pts2) {
    int i = 0;
    while ((i < pts1.length) && (i < pts2.length)) {
      int compare = pts1[i].compareTo(pts2[i]);
      if (compare != 0) return compare;

      i++;
    }
    if (i < pts2.length) return -1;

    if (i < pts1.length) return 1;

    return 0;
  }

  static int increasingDirection(Array<Coordinate> pts) {
    for (int i = 0; i < (pts.length / 2); i++) {
      int j = (pts.length - 1) - i;
      int comp = pts[i].compareTo(pts[j]);
      if (comp != 0) return comp;
    }
    return 1;
  }

  static bool isEqualReversed(Array<Coordinate> pts1, Array<Coordinate> pts2) {
    for (int i = 0; i < pts1.length; i++) {
      Coordinate p1 = pts1[i];
      Coordinate p2 = pts2[(pts1.length - i) - 1];
      if (p1.compareTo(p2) != 0) return false;
    }
    return true;
  }

  static Array<Coordinate> copyDeep(Array<Coordinate> coordinates) {
    Array<Coordinate> copy = Array(coordinates.length);
    for (int i = 0; i < coordinates.length; i++) {
      copy[i] = coordinates[i].copy();
    }
    return copy;
  }

  static void copyDeep2(
      Array<Coordinate> src, int srcStart, Array<Coordinate> dest, int destStart, int length) {
    for (int i = 0; i < length; i++) {
      dest[destStart + i] = src[srcStart + i].copy();
    }
  }

  static Array<Coordinate> toCoordinateArray(List<Coordinate> coordList) {
    return coordList.toArray();
  }

  static bool hasRepeatedPoints(Array<Coordinate> coord) {
    for (int i = 1; i < coord.length; i++) {
      if (coord[i - 1] == coord[i]) {
        return true;
      }
    }
    return false;
  }

  static Array<Coordinate> atLeastNCoordinatesOrNothing(int n, Array<Coordinate> c) {
    return c.length >= n ? c : Array(0);
  }

  static Array<Coordinate> removeRepeatedPoints(Array<Coordinate> coord) {
    if (!hasRepeatedPoints(coord)) return coord;
    CoordinateList coordList = CoordinateList(coord, false);
    return coordList.toCoordinateArray();
  }

  static bool hasRepeatedOrInvalidPoints(Array<Coordinate> coord) {
    for (int i = 1; i < coord.length; i++) {
      if (!coord[i].isValid()) return true;

      if (coord[i - 1] == coord[i]) {
        return true;
      }
    }
    return false;
  }

  static Array<Coordinate> removeRepeatedOrInvalidPoints(Array<Coordinate> coord) {
    if (!hasRepeatedOrInvalidPoints(coord)) return coord;

    CoordinateList coordList = CoordinateList();
    for (int i = 0; i < coord.length; i++) {
      if (!coord[i].isValid()) continue;

      coordList.add3(coord[i], false);
    }
    return coordList.toCoordinateArray();
  }

  static Array<Coordinate> removeNull(Array<Coordinate?> coord) {
    int nonNull = 0;
    for (int i = 0; i < coord.length; i++) {
      if (coord[i] != null) {
        nonNull++;
      }
    }
    Array<Coordinate> newCoord = Array(nonNull);
    if (nonNull == 0) {
      return newCoord;
    }

    int j = 0;
    for (int i = 0; i < coord.length; i++) {
      if (coord[i] != null) {
        newCoord[j++] = coord[i]!;
      }
    }
    return newCoord;
  }

  static void reverse(Array<Coordinate> coord) {
    if (coord.length <= 1) return;

    int last = coord.length - 1;
    int mid = last ~/ 2;
    for (int i = 0; i <= mid; i++) {
      Coordinate tmp = coord[i];
      coord[i] = coord[last - i];
      coord[last - i] = tmp;
    }
  }

  static bool equals(Array<Coordinate>? coord1, Array<Coordinate>? coord2) {
    if (coord1 == coord2) return true;

    if ((coord1 == null) || (coord2 == null)) return false;

    if (coord1.length != coord2.length) return false;

    for (int i = 0; i < coord1.length; i++) {
      if (coord1[i] != coord2[i]) return false;
    }
    return true;
  }

  static bool equals2(
    Array<Coordinate>? coord1,
    Array<Coordinate>? coord2,
    CComparator<Coordinate> coordinateComparator,
  ) {
    if (coord1 == coord2) return true;

    if ((coord1 == null) || (coord2 == null)) return false;

    if (coord1.length != coord2.length) return false;

    for (int i = 0; i < coord1.length; i++) {
      if (coordinateComparator.compare(coord1[i], coord2[i]) != 0) return false;
    }
    return true;
  }

  static Coordinate? minCoordinate(Array<Coordinate> coordinates) {
    Coordinate? minCoord;
    for (int i = 0; i < coordinates.length; i++) {
      if ((minCoord == null) || (minCoord.compareTo(coordinates[i]) > 0)) {
        minCoord = coordinates[i];
      }
    }
    return minCoord;
  }

  static void scroll3(Array<Coordinate> coordinates, Coordinate firstCoordinate) {
    int i = indexOf(firstCoordinate, coordinates);
    scroll(coordinates, i);
  }

  static void scroll(Array<Coordinate> coordinates, int indexOfFirstCoordinate) {
    scroll2(coordinates, indexOfFirstCoordinate, CoordinateArrays.isRing(coordinates));
  }

  static void scroll2(Array<Coordinate> coordinates, int indexOfFirstCoordinate, bool ensureRing) {
    int i = indexOfFirstCoordinate;
    if (i <= 0) return;

    Array<Coordinate> newCoordinates = Array(coordinates.length);
    if (!ensureRing) {
      Array.arrayCopy(coordinates, i, newCoordinates, 0, coordinates.length - i);
      Array.arrayCopy(coordinates, 0, newCoordinates, coordinates.length - i, i);
    } else {
      int last = coordinates.length - 1;
      int j;
      for (j = 0; j < last; j++) {
        newCoordinates[j] = coordinates[(i + j) % last];
      }

      newCoordinates[j] = newCoordinates[0].copy();
    }
    Array.arrayCopy(newCoordinates, 0, coordinates, 0, coordinates.length);
  }

  static int indexOf(Coordinate coordinate, Array<Coordinate> coordinates) {
    for (int i = 0; i < coordinates.length; i++) {
      if (coordinate == coordinates[i]) {
        return i;
      }
    }
    return -1;
  }

  static Array<Coordinate> extract(Array<Coordinate> pts, int start, int end) {
    start = MathUtil.clamp(start, 0, pts.length);
    end = MathUtil.clamp(end, -1, pts.length);
    int npts = (end - start) + 1;
    if (end < 0) npts = 0;

    if (start >= pts.length) npts = 0;

    if (end < start) npts = 0;

    Array<Coordinate> extractPts = Array(npts);
    if (npts == 0) return extractPts;

    int iPts = 0;
    for (int i = start; i <= end; i++) {
      extractPts[iPts++] = pts[i];
    }
    return extractPts;
  }

  static Envelope envelope(Array<Coordinate> coordinates) {
    Envelope env = Envelope();
    for (int i = 0; i < coordinates.length; i++) {
      env.expandToIncludeCoordinate(coordinates[i]);
    }
    return env;
  }

  static Array<Coordinate> intersection(Array<Coordinate> coordinates, Envelope env) {
    CoordinateList coordList = CoordinateList();
    for (int i = 0; i < coordinates.length; i++) {
      if (env.intersectsCoordinate(coordinates[i])) coordList.add3(coordinates[i], true);
    }
    return coordList.toCoordinateArray();
  }
}

class ForwardComparator implements CComparator<Array<Coordinate>> {
  @override
  int compare(Array<Coordinate> o1, Array<Coordinate> o2) {
    return CoordinateArrays.compare(o1, o2);
  }
}

class BidirectionalComparator implements CComparator<Array<Coordinate>> {
  @override
  int compare(Array<Coordinate> pts1, Array<Coordinate> pts2) {
    if (pts1.length < pts2.length) return -1;

    if (pts1.length > pts2.length) return 1;

    if (pts1.length == 0) return 0;

    int forwardComp = CoordinateArrays.compare(pts1, pts2);
    bool isEqualRev = CoordinateArrays.isEqualReversed(pts1, pts2);
    if (isEqualRev) return 0;

    return forwardComp;
  }

  int OLDcompare(Array<Coordinate> pts1, Array<Coordinate> pts2) {
    if (pts1.length < pts2.length) return -1;

    if (pts1.length > pts2.length) return 1;

    if (pts1.length == 0) return 0;

    int dir1 = CoordinateArrays.increasingDirection(pts1);
    int dir2 = CoordinateArrays.increasingDirection(pts2);
    int i1 = (dir1 > 0) ? 0 : pts1.length - 1;
    int i2 = (dir2 > 0) ? 0 : pts1.length - 1;
    for (int i = 0; i < pts1.length; i++) {
      int comparePt = pts1[i1].compareTo(pts2[i2]);
      if (comparePt != 0) return comparePt;

      i1 += dir1;
      i2 += dir2;
    }
    return 0;
  }
}
