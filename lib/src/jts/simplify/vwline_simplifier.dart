import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/triangle.dart';

class VWLineSimplifier {
  static List<Coordinate> simplify2(
      List<Coordinate> pts, double distanceTolerance) {
    return VWLineSimplifier(pts, distanceTolerance).simplify();
  }

  List<Coordinate> pts;
  late double tolerance;

  VWLineSimplifier(this.pts, double distanceTolerance) {
    tolerance = distanceTolerance * distanceTolerance;
  }

  List<Coordinate> simplify() {
    VWVertex vwLine = VWVertex.buildLine(pts)!;
    double minArea = tolerance;
    do {
      minArea = simplifyVertex(vwLine);
    } while (minArea < tolerance);
    final simp = vwLine.getCoordinates();
    if (simp.length < 2) {
      return [simp[0].copy(), simp[0].copy()];
    }
    return CoordinateArrays.copyDeep(simp);
  }

  double simplifyVertex(VWVertex vwLine) {
    VWVertex? curr = vwLine;
    double minArea = curr.getArea();
    VWVertex? minVertex;
    while (curr != null) {
      double area = curr.getArea();
      if (area < minArea) {
        minArea = area;
        minVertex = curr;
      }
      curr = curr._next;
    }
    if ((minVertex != null) && (minArea < tolerance)) {
      minVertex.remove();
    }
    if (!vwLine.isLive()) {
      return -1;
    }

    return minArea;
  }
}

class VWVertex {
  static VWVertex? buildLine(List<Coordinate> pts) {
    VWVertex? first;
    VWVertex? prev;
    for (int i = 0; i < pts.length; i++) {
      VWVertex v = VWVertex(pts[i]);
      first ??= v;
      v.setPrev(prev);
      if (prev != null) {
        prev.setNext(v);
        prev.updateArea();
      }
      prev = v;
    }
    return first;
  }

  static double kMaxArea = double.maxFinite;

  Coordinate pt;

  VWVertex? _prev;

  VWVertex? _next;

  double _area = kMaxArea;

  bool _isLive = true;

  VWVertex(this.pt);

  void setPrev(VWVertex? prev) {
    _prev = prev;
  }

  void setNext(VWVertex? next) {
    _next = next;
  }

  void updateArea() {
    if ((_prev == null) || (_next == null)) {
      _area = kMaxArea;
      return;
    }
    _area = (Triangle.area2(_prev!.pt, pt, _next!.pt)).abs();
  }

  double getArea() {
    return _area;
  }

  bool isLive() {
    return _isLive;
  }

  VWVertex? remove() {
    VWVertex? tmpPrev = _prev;
    VWVertex? tmpNext = _next;
    VWVertex? result;
    if (_prev != null) {
      _prev!.setNext(tmpNext);
      _prev!.updateArea();
      result = _prev;
    }
    if (_next != null) {
      _next!.setPrev(tmpPrev);
      _next!.updateArea();
      result ??= _next;
    }
    _isLive = false;
    return result;
  }

  List<Coordinate> getCoordinates() {
    CoordinateList coords = CoordinateList();
    VWVertex? curr = this;
    do {
      coords.add3(curr!.pt, false);
      curr = curr._next;
    } while (curr != null);
    return coords.toCoordinateList();
  }
}
