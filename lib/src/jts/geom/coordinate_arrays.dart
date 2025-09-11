import 'dart:math';

import 'package:d_util/d_util.dart' show CComparator;
import 'package:dts/src/jts/math/math.dart';

import 'coordinate.dart';
import 'coordinate_list.dart';
import 'envelope.dart';

class CoordinateArrays {
  static int dimension(List<Coordinate>? pts) {
    if ((pts == null) || (pts.isEmpty)) {
      return 3;
    }

    int dimension = 0;
    for (var coordinate in pts) {
      dimension = max(dimension, Coordinates.dimension(coordinate)).toInt();
    }
    return dimension;
  }

  static int measures(List<Coordinate>? pts) {
    if ((pts == null) || (pts.isEmpty)) {
      return 0;
    }
    int measures = 0;
    for (var coordinate in pts) {
      measures = max(measures, Coordinates.measures(coordinate)).toInt();
    }
    return measures;
  }

  static void enforceConsistency(List<Coordinate?>? array) {
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
          maxDimension = max(maxDimension, d).toInt();
          maxMeasures = max(maxMeasures, m).toInt();
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

  static List<Coordinate?> enforceConsistency2(List<Coordinate?> array, int dimension, int measures) {
    final sample = Coordinates.createWithMeasure(dimension, measures);
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
    }

    List<Coordinate?> copy = [];
    for (int i = 0; i < copy.length; i++) {
      final coordinate = array[i];
      if (coordinate != null && coordinate.runtimeType != type) {
        final duplicate = Coordinates.createWithMeasure(dimension, measures);
        duplicate.setCoordinate(coordinate);
        copy.add(duplicate);
      } else {
        copy.add(coordinate);
      }
    }
    return copy;
  }

  static bool isRing(List<Coordinate> pts) {
    if (pts.length < 4) return false;

    if (!pts[0].equals2D(pts[pts.length - 1])) return false;

    return true;
  }

  static Coordinate? ptNotInList(List<Coordinate> testPts, List<Coordinate> pts) {
    for (int i = 0; i < testPts.length; i++) {
      Coordinate testPt = testPts[i];
      if (CoordinateArrays.indexOf(testPt, pts) < 0) return testPt;
    }
    return null;
  }

  static int compare(List<Coordinate> pts1, List<Coordinate> pts2) {
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

  static int increasingDirection(List<Coordinate> pts) {
    for (int i = 0; i < (pts.length / 2); i++) {
      int j = (pts.length - 1) - i;
      int comp = pts[i].compareTo(pts[j]);
      if (comp != 0) return comp;
    }
    return 1;
  }

  static bool isEqualReversed(List<Coordinate> pts1, List<Coordinate> pts2) {
    for (int i = 0; i < pts1.length; i++) {
      Coordinate p1 = pts1[i];
      Coordinate p2 = pts2[(pts1.length - i) - 1];
      if (p1.compareTo(p2) != 0) return false;
    }
    return true;
  }

  static List<Coordinate> copyDeep(List<Coordinate> coordinates) => coordinates.map((e) => e.copy()).toList();

  static void copyDeep2(List<Coordinate> src, int srcStart, List<Coordinate> dest, int destStart, int length) {
    for (int i = 0; i < length; i++) {
      dest[destStart + i] = src[srcStart + i].copy();
    }
  }

  static bool hasRepeatedPoints(List<Coordinate> coord) {
    for (int i = 1; i < coord.length; i++) {
      if (coord[i - 1] == coord[i]) {
        return true;
      }
    }
    return false;
  }

  static List<Coordinate> atLeastNCoordinatesOrNothing(int n, List<Coordinate> c) {
    return c.length >= n ? c : const [];
  }

  static List<Coordinate> removeRepeatedPoints(List<Coordinate> coord) {
    if (!hasRepeatedPoints(coord)) return coord;
    return CoordinateList(coord, false).toCoordinateList();
  }

  static bool hasRepeatedOrInvalidPoints(List<Coordinate> coord) {
    for (int i = 1; i < coord.length; i++) {
      if (!coord[i].isValid()) return true;

      if (coord[i - 1] == coord[i]) {
        return true;
      }
    }
    return false;
  }

  static List<Coordinate> removeRepeatedOrInvalidPoints(List<Coordinate> coord) {
    if (!hasRepeatedOrInvalidPoints(coord)) return coord;

    CoordinateList coordList = CoordinateList();
    for (int i = 0; i < coord.length; i++) {
      if (!coord[i].isValid()) continue;

      coordList.add3(coord[i], false);
    }
    return coordList.toCoordinateList();
  }

  static List<Coordinate> removeNull(List<Coordinate?> coord) => coord.nonNulls.toList();

  static void reverse(List<Coordinate> coord) {
    if (coord.length <= 1) return;

    int last = coord.length - 1;
    int mid = last ~/ 2;
    for (int i = 0; i <= mid; i++) {
      Coordinate tmp = coord[i];
      coord[i] = coord[last - i];
      coord[last - i] = tmp;
    }
  }

  static bool equals(List<Coordinate>? coord1, List<Coordinate>? coord2, [CComparator<Coordinate>? c]) {
    if (coord1 == coord2) return true;
    if ((coord1 == null) || (coord2 == null)) return false;
    if (coord1.length != coord2.length) return false;

    for (int i = 0; i < coord1.length; i++) {
      if (c == null) {
        if (coord1[i] != coord2[i]) return false;
      } else {
        if (c.compare(coord1[i], coord2[i]) != 0) return false;
      }
    }
    return true;
  }

  static Coordinate? minCoordinate(List<Coordinate> coordinates) {
    Coordinate? minCoord;
    for (int i = 0; i < coordinates.length; i++) {
      if ((minCoord == null) || (minCoord.compareTo(coordinates[i]) > 0)) {
        minCoord = coordinates[i];
      }
    }
    return minCoord;
  }

  static void scroll2(List<Coordinate> coordinates, Coordinate firstCoordinate) {
    int i = indexOf(firstCoordinate, coordinates);
    scroll(coordinates, i);
  }

  static void scroll(List<Coordinate> coordinates, int indexOfFirstCoordinate, [bool? ensureRing]) {
    ensureRing ??= CoordinateArrays.isRing(coordinates);

    int i = indexOfFirstCoordinate;
    if (i <= 0) return;
    List<Coordinate> newCoordinates = List.filled(coordinates.length, coordinates[0]);

    if (!ensureRing) {
      newCoordinates.setRange(0, coordinates.length - i, coordinates, i);
      newCoordinates.setRange(coordinates.length - i, coordinates.length, coordinates, 0);
    } else {
      int last = coordinates.length - 1;
      int j;
      for (j = 0; j < last; j++) {
        newCoordinates[j] = coordinates[(i + j) % last];
      }
      newCoordinates[j] = newCoordinates[0].copy();
    }
    coordinates.setRange(0, coordinates.length, newCoordinates);
  }

  static int indexOf(Coordinate coordinate, List<Coordinate> coordinates) {
    for (int i = 0; i < coordinates.length; i++) {
      if (coordinate == coordinates[i]) {
        return i;
      }
    }
    return -1;
  }

  static List<Coordinate> extract(List<Coordinate> pts, int start, int end) {
    start = MathUtil.clamp(start, 0, pts.length);
    end = MathUtil.clamp(end, -1, pts.length);
    int npts = (end - start) + 1;
    if (end < 0) npts = 0;

    if (start >= pts.length) npts = 0;

    if (end < start) npts = 0;
    if (npts == 0) return [];
    return pts.sublist(start, end + 1).toList();
  }

  static Envelope envelope(List<Coordinate> coordinates) {
    Envelope env = Envelope();
    for (int i = 0; i < coordinates.length; i++) {
      env.expandToIncludeCoordinate(coordinates[i]);
    }
    return env;
  }

  static List<Coordinate> intersection(List<Coordinate> coordinates, Envelope env) {
    CoordinateList coordList = CoordinateList();
    for (int i = 0; i < coordinates.length; i++) {
      if (env.intersectsCoordinate(coordinates[i])) {
        coordList.add3(coordinates[i], true);
      }
    }
    return coordList.toCoordinateList();
  }
}

class ForwardComparator implements CComparator<List<Coordinate>> {
  @override
  int compare(List<Coordinate> o1, List<Coordinate> o2) {
    return CoordinateArrays.compare(o1, o2);
  }
}

class BidirectionalComparator implements CComparator<List<Coordinate>> {
  @override
  int compare(List<Coordinate> pts1, List<Coordinate> pts2) {
    if (pts1.length < pts2.length) return -1;

    if (pts1.length > pts2.length) return 1;

    if (pts1.isEmpty) return 0;

    int forwardComp = CoordinateArrays.compare(pts1, pts2);
    bool isEqualRev = CoordinateArrays.isEqualReversed(pts1, pts2);
    if (isEqualRev) return 0;

    return forwardComp;
  }

  int oldCompare(List<Coordinate> pts1, List<Coordinate> pts2) {
    if (pts1.length < pts2.length) return -1;

    if (pts1.length > pts2.length) return 1;

    if (pts1.isEmpty) return 0;

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
