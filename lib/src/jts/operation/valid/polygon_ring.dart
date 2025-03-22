 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';

import 'polygon_ring_self_node.dart';
import 'polygon_ring_touch.dart';

final class PolygonRing {
  static bool isShell(PolygonRing? polyRing) {
    if (polyRing == null) return true;

    return polyRing._isShell();
  }

  static bool addTouchS(PolygonRing? ring0, PolygonRing? ring1, Coordinate pt) {
    if ((ring0 == null) || (ring1 == null)) return false;

    if (!ring0.isSamePolygon(ring1)) return false;

    if (!ring0.isOnlyTouch(ring1, pt)) return true;

    if (!ring1.isOnlyTouch(ring0, pt)) return true;

    ring0.addTouch(ring1, pt);
    ring1.addTouch(ring0, pt);
    return false;
  }

  static Coordinate? findHoleCycleLocationS(List<PolygonRing> polyRings) {
    for (PolygonRing polyRing in polyRings) {
      if (!polyRing.isInTouchSet()) {
        Coordinate? holeCycleLoc = polyRing.findHoleCycleLocation();
        if (holeCycleLoc != null) return holeCycleLoc;
      }
    }
    return null;
  }

  static Coordinate? findInteriorSelfNodeS(List<PolygonRing> polyRings) {
    for (PolygonRing polyRing in polyRings) {
      Coordinate? interiorSelfNode = polyRing.findInteriorSelfNode();
      if (interiorSelfNode != null) {
        return interiorSelfNode;
      }
    }
    return null;
  }

  final LinearRing ring;

  final int id;

  late final PolygonRing _shell;

  PolygonRing? _touchSetRoot;

  Map<int, PolygonRingTouch>? _touches;

  List<PolygonRingSelfNode>? _selfNodes;

  PolygonRing(this.ring, [this.id = -1, PolygonRing? shell]) {
    _shell = shell ?? this;
  }

  bool isSamePolygon(PolygonRing ring) {
    return _shell == ring._shell;
  }

  bool _isShell() {
    return _shell == this;
  }

  bool isInTouchSet() {
    return _touchSetRoot != null;
  }

  void setTouchSetRoot(PolygonRing ring) {
    _touchSetRoot = ring;
  }

  PolygonRing? getTouchSetRoot() {
    return _touchSetRoot;
  }

  bool hasTouches() {
    return (_touches != null) && (_touches!.isNotEmpty);
  }

  List<PolygonRingTouch> getTouches() {
    return _touches!.values.toList();
  }

  void addTouch(PolygonRing ring, Coordinate pt) {
    _touches ??= {};
    PolygonRingTouch? touch = _touches![ring.id];
    if (touch == null) {
      _touches!.put(ring.id, PolygonRingTouch(ring, pt));
    }
  }

  void addSelfTouch(Coordinate origin, Coordinate e00, Coordinate e01, Coordinate e10, Coordinate e11) {
    _selfNodes ??= [];
    _selfNodes!.add(PolygonRingSelfNode(origin, e00, e01, e10, e11));
  }

  bool isOnlyTouch(PolygonRing ring, Coordinate pt) {
    if (_touches == null) return true;

    PolygonRingTouch? touch = _touches![ring.id];
    if (touch == null) return true;

    return touch.isAtLocation(pt);
  }

  Coordinate? findHoleCycleLocation() {
    if (isInTouchSet()) return null;

    PolygonRing root = this;
    root.setTouchSetRoot(root);
    if (!hasTouches()) return null;

    List<PolygonRingTouch> touchStack = [];
    init(root, touchStack);
    while (touchStack.isNotEmpty) {
      PolygonRingTouch touch = touchStack.removeAt(0);
      Coordinate? holeCyclePt = scanForHoleCycle(touch, root, touchStack);
      if (holeCyclePt != null) {
        return holeCyclePt;
      }
    }
    return null;
  }

  static void init(PolygonRing root, List<PolygonRingTouch> touchStack) {
    for (PolygonRingTouch touch in root.getTouches()) {
      touch.getRing().setTouchSetRoot(root);
      touchStack.add(touch);
    }
  }

  Coordinate? scanForHoleCycle(PolygonRingTouch currentTouch, PolygonRing root, List<PolygonRingTouch> touchStack) {
    PolygonRing ring = currentTouch.getRing();
    Coordinate currentPt = currentTouch.getCoordinate();
    for (PolygonRingTouch touch in ring.getTouches()) {
      if (currentPt.equals2D(touch.getCoordinate())) continue;

      PolygonRing touchRing = touch.getRing();
      if (touchRing.getTouchSetRoot() == root) return touch.getCoordinate();

      touchRing.setTouchSetRoot(root);
      touchStack.add(touch);
    }
    return null;
  }

  Coordinate? findInteriorSelfNode() {
    if (_selfNodes == null) return null;

    bool isCCW = Orientation.isCCW(ring.getCoordinates());
    bool isInteriorOnRight = _isShell() ^ isCCW;
    for (PolygonRingSelfNode selfNode in _selfNodes!) {
      if (!selfNode.isExterior(isInteriorOnRight)) {
        return selfNode.getCoordinate();
      }
    }
    return null;
  }

  @override
  String toString() {
    return ring.toString();
  }
}
