import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/math/math.dart';

import 'abstract_node.dart';
import 'item_distance.dart';

abstract interface class Boundable<B> {
  B getBounds();
}

class ItemBoundable<T, B> implements Boundable<B> {
  final B _bounds;

  T item;

  ItemBoundable(this._bounds, this.item);

  @override
  B getBounds() {
    return _bounds;
  }
}

class BoundablePair<B> implements Comparable<BoundablePair<B>> {
  final Boundable<B> _boundable1;
  final Boundable<B> _boundable2;
  double distance = 0;
  final ItemDistance _itemDistance;

  BoundablePair(this._boundable1, this._boundable2, this._itemDistance) {
    distance = distanceF();
  }

  Boundable<B> getBoundable(int i) {
    if (i == 0) {
      return _boundable1;
    }

    return _boundable2;
  }

  double maximumDistance() {
    return EnvelopeDistance.maximumDistance(_boundable1.getBounds() as Envelope,
        _boundable2.getBounds() as Envelope);
  }

  double distanceF() {
    if (isLeaves()) {
      return _itemDistance.distance(
          _boundable1 as ItemBoundable, _boundable2 as ItemBoundable);
    }
    return (_boundable1.getBounds() as Envelope)
        .distance(_boundable2.getBounds() as Envelope);
  }

  double getDistance() {
    return distance;
  }

  @override
  int compareTo(BoundablePair<B> o) {
    if (distance < o.distance) {
      return -1;
    }

    if (distance > o.distance) {
      return 1;
    }

    return 0;
  }

  bool isLeaves() {
    return !(isComposite(_boundable1) || isComposite(_boundable2));
  }

  static bool isComposite(Object item) {
    return item is AbstractNode;
  }

  static double area(Boundable b) {
    return (b.getBounds() as Envelope).area;
  }

  void expandToQueue(PriorityQueue<BoundablePair<B>> priQ, double minDistance) {
    bool isComp1 = isComposite(_boundable1);
    bool isComp2 = isComposite(_boundable2);
    if (isComp1 && isComp2) {
      if (area(_boundable1) > area(_boundable2)) {
        expand(_boundable1, _boundable2, false, priQ, minDistance);
        return;
      } else {
        expand(_boundable2, _boundable1, true, priQ, minDistance);
        return;
      }
    } else if (isComp1) {
      expand(_boundable1, _boundable2, false, priQ, minDistance);
      return;
    } else if (isComp2) {
      expand(_boundable2, _boundable1, true, priQ, minDistance);
      return;
    }
    throw ("neither boundable is composite");
  }

  void expand(
    Boundable<B> bndComposite,
    Boundable<B> bndOther,
    bool isFlipped,
    PriorityQueue<BoundablePair<B>> priQ,
    double minDistance,
  ) {
    final children = ((bndComposite) as AbstractNode<B>).getChildBoundables();
    for (var child in children) {
      BoundablePair<B> bp;
      if (isFlipped) {
        bp = BoundablePair(bndOther, child, _itemDistance);
      } else {
        bp = BoundablePair(child, bndOther, _itemDistance);
      }
      if (bp.getDistance() < minDistance) {
        priQ.add(bp);
      }
    }
  }
}

class BoundablePairDistanceComparator implements CComparator<BoundablePair> {
  bool normalOrder;

  BoundablePairDistanceComparator(this.normalOrder);

  @override
  int compare(BoundablePair p1, BoundablePair p2) {
    double distance1 = p1.getDistance();
    double distance2 = p2.getDistance();
    if (normalOrder) {
      if (distance1 > distance2) {
        return 1;
      } else if (distance1 == distance2) {
        return 0;
      }
      return -1;
    } else {
      if (distance1 > distance2) {
        return -1;
      } else if (distance1 == distance2) {
        return 0;
      }
      return 1;
    }
  }
}

class EnvelopeDistance {
  static double maximumDistance(Envelope env1, Envelope env2) {
    double minx = Math.minD(env1.minX, env2.minX);
    double miny = Math.minD(env1.minY, env2.minY);
    double maxx = Math.maxD(env1.maxX, env2.maxX);
    double maxy = Math.maxD(env1.maxY, env2.maxY);
    return distance(minx, miny, maxx, maxy);
  }

  static double distance(double x1, double y1, double x2, double y2) {
    double dx = x2 - x1;
    double dy = y2 - y1;
    return MathUtil.hypot(dx, dy);
  }

  static double minMaxDistance(Envelope a, Envelope b) {
    double aminx = a.minX;
    double aminy = a.minY;
    double amaxx = a.maxX;
    double amaxy = a.maxY;
    double bminx = b.minX;
    double bminy = b.minY;
    double bmaxx = b.maxX;
    double bmaxy = b.maxY;
    double dist =
        maxDistance(aminx, aminy, aminx, amaxy, bminx, bminy, bminx, bmaxy);
    dist = Math.minD(dist,
        maxDistance(aminx, aminy, aminx, amaxy, bminx, bminy, bmaxx, bminy));
    dist = Math.minD(dist,
        maxDistance(aminx, aminy, aminx, amaxy, bmaxx, bmaxy, bminx, bmaxy));
    dist = Math.minD(dist,
        maxDistance(aminx, aminy, aminx, amaxy, bmaxx, bmaxy, bmaxx, bminy));
    dist = Math.minD(dist,
        maxDistance(aminx, aminy, amaxx, aminy, bminx, bminy, bminx, bmaxy));
    dist = Math.minD(dist,
        maxDistance(aminx, aminy, amaxx, aminy, bminx, bminy, bmaxx, bminy));
    dist = Math.minD(dist,
        maxDistance(aminx, aminy, amaxx, aminy, bmaxx, bmaxy, bminx, bmaxy));
    dist = Math.minD(dist,
        maxDistance(aminx, aminy, amaxx, aminy, bmaxx, bmaxy, bmaxx, bminy));
    dist = Math.minD(dist,
        maxDistance(amaxx, amaxy, aminx, amaxy, bminx, bminy, bminx, bmaxy));
    dist = Math.minD(dist,
        maxDistance(amaxx, amaxy, aminx, amaxy, bminx, bminy, bmaxx, bminy));
    dist = Math.minD(dist,
        maxDistance(amaxx, amaxy, aminx, amaxy, bmaxx, bmaxy, bminx, bmaxy));
    dist = Math.minD(dist,
        maxDistance(amaxx, amaxy, aminx, amaxy, bmaxx, bmaxy, bmaxx, bminy));
    dist = Math.minD(dist,
        maxDistance(amaxx, amaxy, amaxx, aminy, bminx, bminy, bminx, bmaxy));
    dist = Math.minD(dist,
        maxDistance(amaxx, amaxy, amaxx, aminy, bminx, bminy, bmaxx, bminy));
    dist = Math.minD(dist,
        maxDistance(amaxx, amaxy, amaxx, aminy, bmaxx, bmaxy, bminx, bmaxy));
    dist = Math.minD(dist,
        maxDistance(amaxx, amaxy, amaxx, aminy, bmaxx, bmaxy, bmaxx, bminy));
    return dist;
  }

  static double maxDistance(
    double ax1,
    double ay1,
    double ax2,
    double ay2,
    double bx1,
    double by1,
    double bx2,
    double by2,
  ) {
    double dist = distance(ax1, ay1, bx1, by1);
    dist = Math.maxD(dist, distance(ax1, ay1, bx2, by2));
    dist = Math.maxD(dist, distance(ax2, ay2, bx1, by1));
    dist = Math.maxD(dist, distance(ax2, ay2, bx2, by2));
    return dist;
  }
}
