import 'package:d_util/d_util.dart' show CComparator, CComparator2;
import 'package:dts/src/jts/edgegraph/edge_graph.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';

import 'maximal_edge_ring.dart';
import 'overlay_edge_ring.dart';
import 'overlay_label.dart';

class OverlayEdge extends HalfEdge {
  static OverlayEdge createEdge(
      List<Coordinate> pts, OverlayLabel lbl, bool direction) {
    Coordinate origin;
    Coordinate dirPt;
    if (direction) {
      origin = pts[0];
      dirPt = pts[1];
    } else {
      int ilast = pts.length - 1;
      origin = pts[ilast];
      dirPt = pts[ilast - 1];
    }
    return OverlayEdge(origin, dirPt, direction, lbl, pts);
  }

  static OverlayEdge createEdgePair(List<Coordinate> pts, OverlayLabel lbl) {
    OverlayEdge e0 = OverlayEdge.createEdge(pts, lbl, true);
    OverlayEdge e1 = OverlayEdge.createEdge(pts, lbl, false);
    e0.link(e1);
    return e0;
  }

  static CComparator<OverlayEdge> nodeComparator() {
    return CComparator2<OverlayEdge>((e1, e2) {
      return e1.orig().compareTo(e2.orig());
    });
  }

  List<Coordinate> pts;

  final bool _direction;

  final Coordinate _dirPt;

  final OverlayLabel _label;

  bool _isInResultArea = false;

  bool _isInResultLine = false;

  bool isVisited = false;

  OverlayEdge? _nextResultEdge;

  OverlayEdgeRing? _edgeRing;

  NgMaximalEdgeRing? _maxEdgeRing;

  OverlayEdge? _nextResultMaxEdge;

  OverlayEdge(super.orig, this._dirPt, this._direction, this._label, this.pts);

  bool isForward() {
    return _direction;
  }

  @override
  Coordinate directionPt() {
    return _dirPt;
  }

  OverlayLabel getLabel() {
    return _label;
  }

  int getLocation(int index, int position) {
    return _label.getLocation2(index, position, _direction);
  }

  Coordinate getCoordinate() {
    return orig();
  }

  List<Coordinate> getCoordinates() {
    return pts;
  }

  List<Coordinate> getCoordinatesOriented() {
    if (_direction) {
      return pts;
    }
    List<Coordinate> copy = pts.toList();
    CoordinateArrays.reverse(copy);
    return copy;
  }

  void addCoordinates(CoordinateList coords) {
    bool isFirstEdge = coords.size > 0;
    if (_direction) {
      int startIndex = 1;
      if (isFirstEdge) {
        startIndex = 0;
      }

      for (int i = startIndex; i < pts.length; i++) {
        coords.add3(pts[i], false);
      }
    } else {
      int startIndex = pts.length - 2;
      if (isFirstEdge) {
        startIndex = pts.length - 1;
      }

      for (int i = startIndex; i >= 0; i--) {
        coords.add3(pts[i], false);
      }
    }
  }

  OverlayEdge symOE() {
    return sym() as OverlayEdge;
  }

  OverlayEdge? oNextOE() {
    return oNext() as OverlayEdge?;
  }

  bool isInResultArea() {
    return _isInResultArea;
  }

  bool isInResultAreaBoth() {
    return _isInResultArea && symOE()._isInResultArea;
  }

  void unmarkFromResultAreaBoth() {
    _isInResultArea = false;
    symOE()._isInResultArea = false;
  }

  void markInResultArea() {
    _isInResultArea = true;
  }

  void markInResultAreaBoth() {
    _isInResultArea = true;
    symOE()._isInResultArea = true;
  }

  bool isInResultLine() {
    return _isInResultLine;
  }

  void markInResultLine() {
    _isInResultLine = true;
    symOE()._isInResultLine = true;
  }

  bool isInResult() {
    return _isInResultArea || _isInResultLine;
  }

  bool isInResultEither() {
    return isInResult() || symOE().isInResult();
  }

  void setNextResult(OverlayEdge e) {
    _nextResultEdge = e;
  }

  OverlayEdge? nextResult() {
    return _nextResultEdge;
  }

  bool isResultLinked() {
    return _nextResultEdge != null;
  }

  void setNextResultMax(OverlayEdge e) {
    _nextResultMaxEdge = e;
  }

  OverlayEdge? nextResultMax() {
    return _nextResultMaxEdge;
  }

  bool isResultMaxLinked() {
    return _nextResultMaxEdge != null;
  }

  void markVisited() {
    isVisited = true;
  }

  void markVisitedBoth() {
    markVisited();
    symOE().markVisited();
  }

  void setEdgeRing(OverlayEdgeRing edgeRing) {
    _edgeRing = edgeRing;
  }

  OverlayEdgeRing? getEdgeRing() {
    return _edgeRing;
  }

  NgMaximalEdgeRing? getEdgeRingMax() {
    return _maxEdgeRing;
  }

  void setEdgeRingMax(NgMaximalEdgeRing maximalEdgeRing) {
    _maxEdgeRing = maximalEdgeRing;
  }

  String resultSymbol() {
    if (_isInResultArea) {
      return " resA";
    }

    if (_isInResultLine) {
      return " resL";
    }

    return "";
  }
}
