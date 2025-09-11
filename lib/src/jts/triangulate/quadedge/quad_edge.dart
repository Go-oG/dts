import 'package:dts/src/jts/geom/line_segment.dart';

import 'vertex.dart';

class QuadEdge {
  static QuadEdge makeEdge(Vertex o, Vertex d) {
    QuadEdge q0 = QuadEdge();
    QuadEdge q1 = QuadEdge();
    QuadEdge q2 = QuadEdge();
    QuadEdge q3 = QuadEdge();
    q0._rot = q1;
    q1._rot = q2;
    q2._rot = q3;
    q3._rot = q0;
    q0.setNext(q0);
    q1.setNext(q3);
    q2.setNext(q2);
    q3.setNext(q1);
    QuadEdge base = q0;
    base.setOrig(o);
    base.setDest(d);
    return base;
  }

  static QuadEdge connect(QuadEdge a, QuadEdge b) {
    QuadEdge e = makeEdge(a.dest(), b.orig());
    splice(e, a.lNext());
    splice(e.sym(), b);
    return e;
  }

  static void splice(QuadEdge a, QuadEdge b) {
    QuadEdge alpha = a.oNext().rot();
    QuadEdge beta = b.oNext().rot();
    QuadEdge t1 = b.oNext();
    QuadEdge t2 = a.oNext();
    QuadEdge t3 = beta.oNext();
    QuadEdge t4 = alpha.oNext();
    a.setNext(t1);
    b.setNext(t2);
    alpha.setNext(t3);
    beta.setNext(t4);
  }

  static void swap(QuadEdge e) {
    QuadEdge a = e.oPrev();
    QuadEdge b = e.sym().oPrev();
    splice(e, a);
    splice(e.sym(), b);
    splice(e, a.lNext());
    splice(e.sym(), b.lNext());
    e.setOrig(a.dest());
    e.setDest(b.dest());
  }

  QuadEdge? _rot;

  Vertex? _vertex;

  QuadEdge? _next;

  Object? data;

  QuadEdge? getPrimary() {
    if (orig().getCoordinate().compareTo(dest().getCoordinate()) <= 0) {
      return this;
    } else {
      return sym();
    }
  }

  void delete() {
    _rot = null;
  }

  bool isLive() {
    return _rot != null;
  }

  void setNext(QuadEdge next) {
    _next = next;
  }

  QuadEdge rot() {
    return rot2()!;
  }

  QuadEdge? rot2() {
    return _rot;
  }

  QuadEdge? invRot() {
    return _rot?.sym();
  }

  QuadEdge sym() {
    return sym2()!;
  }

  QuadEdge? sym2() {
    return _rot!._rot;
  }

  QuadEdge oNext() {
    return oNext2()!;
  }

  QuadEdge? oNext2() {
    return _next;
  }

  QuadEdge oPrev() {
    return oPrev2()!;
  }

  QuadEdge? oPrev2() {
    return _rot?._next?._rot;
  }

  QuadEdge? dNext() {
    return sym().oNext().sym();
  }

  QuadEdge? dPrev() {
    return invRot()?.oNext().invRot();
  }

  QuadEdge lNext() {
    return lNext2()!;
  }

  QuadEdge? lNext2() {
    return invRot()?.oNext().rot();
  }

  QuadEdge? lPrev() {
    return _next?.sym();
  }

  QuadEdge? rNext() {
    return _rot?._next?.invRot();
  }

  QuadEdge? rPrev() {
    return sym().oNext();
  }

  void setOrig(Vertex o) {
    _vertex = o;
  }

  void setDest(Vertex d) {
    sym().setOrig(d);
  }

  Vertex orig() {
    return orig2()!;
  }

  Vertex? orig2() {
    return _vertex;
  }

  Vertex dest() {
    return sym().orig();
  }

  Vertex? dest2() {
    return sym().orig();
  }

  double getLength() {
    return orig().getCoordinate().distance(dest().getCoordinate());
  }

  bool equalsNonOriented(QuadEdge qe) {
    if (equalsOriented(qe)) return true;

    if (equalsOriented(qe.sym())) return true;

    return false;
  }

  bool equalsOriented(QuadEdge qe) {
    if (orig().getCoordinate().equals2D(qe.orig().getCoordinate()) &&
        dest().getCoordinate().equals2D(qe.dest().getCoordinate())) {
      return true;
    }

    return false;
  }

  LineSegment toLineSegment() {
    return LineSegment(_vertex!.getCoordinate(), dest().getCoordinate());
  }
}
