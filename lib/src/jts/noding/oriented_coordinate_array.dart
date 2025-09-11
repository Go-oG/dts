import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';

class OrientedCoordinateArray implements Comparable<OrientedCoordinateArray> {
  List<Coordinate> pts;

  bool _orientation = false;

  OrientedCoordinateArray(this.pts) {
    _orientation = orientation(pts);
  }

  static bool orientation(List<Coordinate> pts) {
    return CoordinateArrays.increasingDirection(pts) == 1;
  }

  @override
  int compareTo(OrientedCoordinateArray oca) {
    int comp = compareOriented(pts, _orientation, oca.pts, oca._orientation);
    return comp;
  }

  static int compareOriented(List<Coordinate> pts1, bool orientation1,
      List<Coordinate> pts2, bool orientation2) {
    int dir1 = (orientation1) ? 1 : -1;
    int dir2 = (orientation2) ? 1 : -1;
    int limit1 = (orientation1) ? pts1.length : -1;
    int limit2 = (orientation2) ? pts2.length : -1;
    int i1 = (orientation1) ? 0 : pts1.length - 1;
    int i2 = (orientation2) ? 0 : pts2.length - 1;
    while (true) {
      int compPt = pts1[i1].compareTo(pts2[i2]);
      if (compPt != 0) return compPt;

      i1 += dir1;
      i2 += dir2;
      bool done1 = i1 == limit1;
      bool done2 = i2 == limit2;
      if (done1 && (!done2)) return -1;

      if ((!done1) && done2) return 1;

      if (done1 && done2) return 0;
    }
  }
}
