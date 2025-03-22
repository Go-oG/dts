 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/triangle.dart';

class VWLineSimplifier {
  static Array<Coordinate> simplify2(Array<Coordinate> pts, double distanceTolerance) {
    VWLineSimplifier simp = VWLineSimplifier(pts, distanceTolerance);
    return simp.simplify();
  }

  Array<Coordinate> pts;
  late double tolerance;

  VWLineSimplifier(this.pts, double distanceTolerance) {
    tolerance = distanceTolerance * distanceTolerance;
  }

  Array<Coordinate> simplify() {
    VWVertex vwLine = VWVertex.buildLine(pts)!;
    double minArea = tolerance;
    do {
      minArea = simplifyVertex(vwLine);
    } while (minArea < tolerance);
    Array<Coordinate> simp = vwLine.getCoordinates();
    if (simp.length < 2) {
      return [simp[0].copy(), simp[0].copy()].toArray();
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
  static VWVertex? buildLine(Array<Coordinate> pts) {
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

  static double MAX_AREA = double.maxFinite;

  Coordinate pt;

  VWVertex? _prev;

  VWVertex? _next;

  double _area = MAX_AREA;

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
      _area = MAX_AREA;
      return;
    }
    _area = Math.abs(Triangle.area2(_prev!.pt, pt, _next!.pt));
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

  Array<Coordinate> getCoordinates() {
    CoordinateList coords = CoordinateList();
    VWVertex? curr = this;
    do {
      coords.add3(curr!.pt, false);
      curr = curr._next;
    } while (curr != null);
    return coords.toCoordinateArray();
  }
}
