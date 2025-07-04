import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/triangle.dart';
import 'package:dts/src/jts/simplify/linked_line.dart';

class Corner implements Comparable<Corner> {
  final LinkedLine _edge;

  final int _index;

  int _prev = 0;

  int _next = 0;

  final double _area;

  Corner(this._edge, this._index, this._area) {
    _prev = _edge.prev(_index);
    _next = _edge.next(_index);
  }

  bool isVertex(int index) {
    return ((index == _index) || (index == _prev)) || (index == _next);
  }

  int getIndex() {
    return _index;
  }

  Coordinate getCoordinate() {
    return _edge.getCoordinate(_index);
  }

  double getArea() {
    return _area;
  }

  Coordinate prev() {
    return _edge.getCoordinate(_prev);
  }

  Coordinate next() {
    return _edge.getCoordinate(_next);
  }

  @override
  int compareTo(Corner o) {
    int comp = Double.compare(_area, o._area);
    if (comp != 0) {
      return comp;
    }

    return _index.compareTo(o._index);
  }

  Envelope envelope() {
    Coordinate pp = _edge.getCoordinate(_prev);
    Coordinate p = _edge.getCoordinate(_index);
    Coordinate pn = _edge.getCoordinate(_next);
    Envelope env = Envelope.of(pp, pn);
    env.expandToIncludeCoordinate(p);
    return env;
  }

  bool isVertex2(Coordinate v) {
    if (v.equals2D(_edge.getCoordinate(_prev))) {
      return true;
    }

    if (v.equals2D(_edge.getCoordinate(_index))) {
      return true;
    }

    if (v.equals2D(_edge.getCoordinate(_next))) {
      return true;
    }

    return false;
  }

  bool isBaseline(Coordinate p0, Coordinate p1) {
    Coordinate prevV = prev();
    Coordinate nextV = next();
    if (prevV.equals2D(p0) && nextV.equals2D(p1)) {
      return true;
    }

    if (prevV.equals2D(p1) && nextV.equals2D(p0)) {
      return true;
    }

    return false;
  }

  bool intersects(Coordinate v) {
    Coordinate pp = _edge.getCoordinate(_prev);
    Coordinate p = _edge.getCoordinate(_index);
    Coordinate pn = _edge.getCoordinate(_next);
    return Triangle.intersects(pp, p, pn, v);
  }

  bool isRemoved() {
    return (_edge.prev(_index) != _prev) || (_edge.next(_index) != _next);
  }

  LineString toLineString() {
    Coordinate pp = _edge.getCoordinate(_prev);
    Coordinate p = _edge.getCoordinate(_index);
    Coordinate pn = _edge.getCoordinate(_next);
    return GeometryFactory()
        .createLineString2([_safeCoord(pp), _safeCoord(p), _safeCoord(pn)].toArray());
  }

  @override
  String toString() {
    return toLineString().toString();
  }

  static Coordinate _safeCoord(Coordinate p) {
    return p;
  }
}
