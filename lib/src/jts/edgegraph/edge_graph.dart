import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';

import '../geom/coordinate.dart';
import '../geom/geom.dart';
import '../geom/geom_component_filter.dart';
import '../geom/line_string.dart';
import '../geom/quadrant.dart';
import '../util/assert.dart';

class EdgeGraph {
  final Map<Coordinate, HalfEdge> _vertexMap = {};

  static bool isValidEdge(Coordinate orig, Coordinate dest) {
    int cmp = dest.compareTo(orig);
    return cmp != 0;
  }

  HalfEdge createEdge(Coordinate orig) => HalfEdge(orig);

  HalfEdge _create(Coordinate p0, Coordinate p1) {
    HalfEdge e0 = createEdge(p0);
    HalfEdge e1 = createEdge(p1);
    e0.link(e1);
    return e0;
  }

  HalfEdge? addEdge(Coordinate orig, Coordinate dest) {
    if (!isValidEdge(orig, dest)) {
      return null;
    }

    HalfEdge? eAdj = _vertexMap[orig];
    HalfEdge? eSame;
    if (eAdj != null) {
      eSame = eAdj.find(dest);
    }
    if (eSame != null) {
      return eSame;
    }
    HalfEdge e = _insert(orig, dest, eAdj);
    return e;
  }

  HalfEdge _insert(Coordinate orig, Coordinate dest, HalfEdge? eAdj) {
    HalfEdge? e = _create(orig, dest);
    if (eAdj != null) {
      eAdj.insert(e);
    } else {
      _vertexMap.put(orig, e);
    }
    HalfEdge? eAdjDest = _vertexMap[dest];
    if (eAdjDest != null) {
      eAdjDest.insert(e.sym());
    } else {
      _vertexMap.put(dest, e.sym());
    }
    return e;
  }

  List<HalfEdge> getVertexEdges() {
    return _vertexMap.values.toList();
  }

  HalfEdge? findEdge(Coordinate orig, Coordinate dest) {
    HalfEdge? e = _vertexMap.get(orig);
    if (e == null) {
      return null;
    }
    return e.find(dest);
  }
}

class EdgeGraphBuilder {
  static EdgeGraph build(List<Geometry> geoms) {
    EdgeGraphBuilder builder = EdgeGraphBuilder();
    builder.addAll(geoms);
    return builder.getGraph();
  }

  final EdgeGraph _graph = EdgeGraph();

  EdgeGraph getGraph() {
    return _graph;
  }

  void add(Geometry geometry) {
    geometry.apply4(
      GeomComponentFilter2((c) {
        if (c is LineString) {
          _add(c);
        }
      }),
    );
  }

  void addAll(List<Geometry> geometries) {
    for (var item in geometries) {
      add(item);
    }
  }

  void _add(LineString lineString) {
    final seq = lineString.getCoordinateSequence();
    for (int i = 1; i < seq.size(); i++) {
      _graph.addEdge(seq.getCoordinate(i - 1), seq.getCoordinate(i));
    }
  }
}

class HalfEdge {
  final Coordinate _orig;
  late HalfEdge _sym;
  HalfEdge? _next;
  HalfEdge(this._orig);

  static HalfEdge create(Coordinate p0, Coordinate p1) {
    HalfEdge e0 = HalfEdge(p0);
    HalfEdge e1 = HalfEdge(p1);
    e0.link(e1);
    return e0;
  }

  void link(HalfEdge sym) {
    _setSym(sym);
    sym._setSym(this);
    _setNext(sym);
    sym._setNext(this);
  }

  Coordinate orig() {
    return _orig;
  }

  Coordinate dest() {
    return _sym._orig;
  }

  double directionX() {
    return directionPt().x - _orig.x;
  }

  double directionY() {
    return directionPt().y - _orig.y;
  }

  Coordinate directionPt() {
    return dest();
  }

  HalfEdge sym() {
    return _sym;
  }

  void _setSym(HalfEdge e) {
    _sym = e;
  }

  void _setNext(HalfEdge e) {
    _next = e;
  }

  HalfEdge? next() {
    return _next;
  }

  HalfEdge prev() {
    HalfEdge? curr = this;
    HalfEdge? prev = this;
    do {
      prev = curr;
      curr = curr!.oNext();
    } while (curr != this);
    return prev!._sym;
  }

  HalfEdge? oNext() {
    return _sym._next;
  }

  HalfEdge? find(Coordinate dest) {
    HalfEdge? oNext = this;
    do {
      if (oNext!.dest().equals2D(dest)) {
        return oNext;
      }

      oNext = oNext.oNext();
    } while (oNext != this);
    return null;
  }

  bool equals(Coordinate p0, Coordinate p1) {
    return _orig.equals2D(p0) && _sym._orig == p1;
  }

  void insert(HalfEdge eAdd) {
    if (oNext() == this) {
      _insertAfter(eAdd);
      return;
    }
    HalfEdge ePrev = _insertionEdge(eAdd)!;
    ePrev._insertAfter(eAdd);
  }

  HalfEdge? _insertionEdge(HalfEdge eAdd) {
    HalfEdge ePrev = this;
    do {
      HalfEdge eNext = ePrev.oNext()!;
      if (((eNext.compareTo(ePrev) > 0) && (eAdd.compareTo(ePrev) >= 0)) &&
          (eAdd.compareTo(eNext) <= 0)) {
        return ePrev;
      }
      if ((eNext.compareTo(ePrev) <= 0) &&
          ((eAdd.compareTo(eNext) <= 0) || (eAdd.compareTo(ePrev) >= 0))) {
        return ePrev;
      }
      ePrev = eNext;
    } while (ePrev != this);
    Assert.shouldNeverReachHere();
    return null;
  }

  void _insertAfter(HalfEdge e) {
    Assert.equals(_orig, e.orig());
    HalfEdge save = oNext()!;
    _sym._setNext(e);
    e.sym()._setNext(save);
  }

  bool isEdgesSorted() {
    HalfEdge lowest = _findLowest();
    HalfEdge e = lowest;
    do {
      HalfEdge eNext = e.oNext()!;
      if (eNext == lowest) {
        break;
      }

      bool isSorted = eNext.compareTo(e) > 0;
      if (!isSorted) {
        return false;
      }
      e = eNext;
    } while (e != lowest);
    return true;
  }

  HalfEdge _findLowest() {
    HalfEdge lowest = this;
    HalfEdge e = oNext()!;
    do {
      if (e.compareTo(lowest) < 0) {
        lowest = e;
      }
      e = e.oNext()!;
    } while (e != this);
    return lowest;
  }

  int compareTo(Object obj) {
    HalfEdge e = (obj as HalfEdge);
    int comp = compareAngularDirection(e);
    return comp;
  }

  int compareAngularDirection(HalfEdge e) {
    double dx = directionX();
    double dy = directionY();
    double dx2 = e.directionX();
    double dy2 = e.directionY();
    if ((dx == dx2) && (dy == dy2)) {
      return 0;
    }

    int quadrant = Quadrant.quadrant(dx, dy);
    int quadrant2 = Quadrant.quadrant(dx2, dy2);
    if (quadrant > quadrant2) {
      return 1;
    }

    if (quadrant < quadrant2) {
      return -1;
    }

    Coordinate dir1 = directionPt();
    Coordinate dir2 = e.directionPt();
    return Orientation.index(e._orig, dir2, dir1);
  }

  int degree() {
    int degree = 0;
    HalfEdge e = this;
    do {
      degree++;
      e = e.oNext()!;
    } while (e != this);
    return degree;
  }

  HalfEdge? prevNode() {
    HalfEdge e = this;
    while (e.degree() == 2) {
      e = e.prev();
      if (e == this) {
        return null;
      }
    }
    return e;
  }
}

class MarkHalfEdge extends HalfEdge {
  static bool isMarkedS(HalfEdge e) {
    return (e as MarkHalfEdge).isMarked;
  }

  static void markS(HalfEdge e) {
    ((e as MarkHalfEdge)).mark();
  }

  static void setMarkS(HalfEdge e, bool isMarked) {
    ((e as MarkHalfEdge)).setMark(isMarked);
  }

  static void setMarkBoth(HalfEdge e, bool isMarked) {
    ((e as MarkHalfEdge)).setMark(isMarked);
    ((e.sym() as MarkHalfEdge)).setMark(isMarked);
  }

  static void markBoth(HalfEdge e) {
    ((e as MarkHalfEdge)).mark();
    ((e.sym() as MarkHalfEdge)).mark();
  }

  bool isMarked = false;

  MarkHalfEdge(super._orig);

  void mark() {
    isMarked = true;
  }

  void setMark(bool isMarked) {
    this.isMarked = isMarked;
  }
}
