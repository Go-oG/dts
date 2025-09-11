import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

class DouglasPeuckerLineSimplifier {
  static List<Coordinate> simplify2(
      List<Coordinate> pts, double distanceTolerance, bool isPreserveEndpoint) {
    final simp = DouglasPeuckerLineSimplifier(pts);
    simp.setDistanceTolerance(distanceTolerance);
    simp.setPreserveEndpoint(isPreserveEndpoint);
    return simp.simplify();
  }

  List<Coordinate> pts;

  late List<bool> _usePt;

  double distanceTolerance = 0;

  bool _isPreserveEndpoint = false;

  DouglasPeuckerLineSimplifier(this.pts);

  void setDistanceTolerance(double distanceTolerance) {
    this.distanceTolerance = distanceTolerance;
  }

  void setPreserveEndpoint(bool isPreserveEndpoint) {
    _isPreserveEndpoint = isPreserveEndpoint;
  }

  List<Coordinate> simplify() {
    _usePt = List.filled(pts.length, false);
    for (int i = 0; i < pts.length; i++) {
      _usePt[i] = true;
    }
    simplifySection(0, pts.length - 1);
    CoordinateList coordList = CoordinateList();
    for (int i = 0; i < pts.length; i++) {
      if (_usePt[i]) {
        coordList.add(pts[i].copy());
      }
    }
    if ((!_isPreserveEndpoint) && CoordinateArrays.isRing(pts)) {
      simplifyRingEndpoint(coordList);
    }
    return coordList.toCoordinateList();
  }

  void simplifyRingEndpoint(CoordinateList pts) {
    if (pts.size < 4) return;

    seg.p0 = pts.get(1);
    seg.p1 = pts.get(pts.size - 2);
    double distance = seg.distance(pts.get(0));
    if (distance <= distanceTolerance) {
      pts.remove(0);
      pts.remove(pts.size - 1);
      pts.closeRing();
    }
  }

  LineSegment seg = LineSegment.empty();

  void simplifySection(int i, int j) {
    if ((i + 1) == j) {
      return;
    }
    seg.p0 = pts[i];
    seg.p1 = pts[j];
    double maxDistance = -1.0;
    int maxIndex = i;
    for (int k = i + 1; k < j; k++) {
      double distance = seg.distance(pts[k]);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = k;
      }
    }
    if (maxDistance <= distanceTolerance) {
      for (int k = i + 1; k < j; k++) {
        _usePt[k] = false;
      }
    } else {
      simplifySection(i, maxIndex);
      simplifySection(maxIndex, j);
    }
  }
}
