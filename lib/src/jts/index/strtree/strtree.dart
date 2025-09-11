import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/index/item_visitor.dart';
import 'package:dts/src/jts/index/spatial_index.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'abstract_node.dart';
import 'abstract_strtree.dart';
import 'boundable.dart';
import 'item_distance.dart';

class STRtree<T> extends AbstractSTRtree<T, Envelope>
    implements SpatialIndex<T> {
  static final _xComparator = CComparator2<Boundable<Envelope>>((o1, o2) {
    final v1 = o1.getBounds();
    final v2 = o2.getBounds();

    return AbstractSTRtree.compareDoubles(centreX(v1), centreX(v2));
  });

  static final _yComparator = CComparator2<Boundable<Envelope>>((o1, o2) {
    final v1 = o1.getBounds();
    final v2 = o2.getBounds();
    return AbstractSTRtree.compareDoubles(centreY(v1), centreY(v2));
  });

  static double centreX(Envelope e) {
    return avg(e.minX, e.maxX);
  }

  static double centreY(Envelope e) {
    return avg(e.minY, e.maxY);
  }

  static double avg(double a, double b) {
    return (a + b) / 2.0;
  }

  static final _intersectsOp = IntersectsOp2<Envelope>((a, b) {
    return a.intersects(b);
  });

  @override
  List<AbstractNode<Envelope>> createParentBoundables(
      List<Boundable<Envelope>> childBoundables, int newLevel) {
    Assert.isTrue(childBoundables.isNotEmpty);
    int minLeafCount = Math.ceil(childBoundables.size / getNodeCapacity());
    List<Boundable<Envelope>> sortedChildBoundables =
        List.from(childBoundables);
    sortedChildBoundables.sort(_xComparator.compare);
    Array<List<Boundable<Envelope>>> vv = verticalSlices(
        sortedChildBoundables, Math.ceil(Math.sqrt(minLeafCount)));
    return createParentBoundablesFromVerticalSlices(vv, newLevel);
  }

  List<AbstractNode<Envelope>> createParentBoundablesFromVerticalSlices(
    Array<List<Boundable<Envelope>>> verticalSlices,
    int newLevel,
  ) {
    Assert.isTrue(verticalSlices.isNotEmpty);
    List<AbstractNode<Envelope>> parentBoundables = [];
    for (var i in verticalSlices) {
      parentBoundables
          .addAll(createParentBoundablesFromVerticalSlice(i, newLevel));
    }

    return parentBoundables;
  }

  List<AbstractNode<Envelope>> createParentBoundablesFromVerticalSlice(
    List<Boundable<Envelope>> childBoundables,
    int newLevel,
  ) {
    return super.createParentBoundables(childBoundables, newLevel);
  }

  Array<List<Boundable<Envelope>>> verticalSlices(
      List<Boundable<Envelope>> childBoundables, int sliceCount) {
    int sliceCapacity = Math.ceil(childBoundables.size / sliceCount);
    Array<List<Boundable<Envelope>>> slices = Array(sliceCount);
    final i = childBoundables.iterator;
    for (int j = 0; j < sliceCount; j++) {
      slices[j] = [];
      int boundablesAddedToSlice = 0;
      while (i.moveNext() && (boundablesAddedToSlice < sliceCapacity)) {
        slices[j].add(i.current);
        boundablesAddedToSlice++;
      }
    }
    return slices;
  }

  STRtree([super.nodeCapacity = 10]);

  STRtree.of([super.nodeCapacity = 10, STRtreeNode? super.root]) : super.of();

  STRtree.of2(
      super.nodeCapacity, List<Boundable<Envelope>> super.itemBoundables)
      : super.of2();

  @override
  AbstractNode<Envelope> createNode(int level) {
    return STRtreeNode(level);
  }

  @override
  IntersectsOp<Envelope> getIntersectsOp() {
    return _intersectsOp;
  }

  @override
  void insert(Envelope bounds, T item) {
    if (bounds.isNull) {
      return;
    }
    super.insert(bounds, item);
  }

  @override
  void each(covariant Envelope searchBounds, ItemVisitor<T> visitor) {
    super.query2(searchBounds, visitor);
  }

  @override
  CComparator<Boundable<Envelope>> getComparator() {
    return _yComparator;
  }

  Array<T>? nearestNeighbour(ItemDistance itemDist) {
    if (isEmpty()) return null;
    final bp = BoundablePair(getRoot(), getRoot(), itemDist);
    return nearestNeighbour5(bp);
  }

  Object? nearestNeighbour4(Envelope env, T item, ItemDistance itemDist) {
    if (isEmpty()) return null;

    final bnd = ItemBoundable(env, item);
    final bp = BoundablePair<Envelope>(getRoot(), bnd, itemDist);
    return nearestNeighbour5(bp)![0];
  }

  Array<T>? nearestNeighbour2(STRtree<T> tree, ItemDistance itemDist) {
    if (isEmpty() || tree.isEmpty()) return null;

    final bp = BoundablePair<Envelope>(getRoot(), tree.getRoot(), itemDist);
    return nearestNeighbour5(bp);
  }

  Array<T>? nearestNeighbour5(BoundablePair<Envelope> initBndPair) {
    double distanceLowerBound = double.infinity;
    BoundablePair? minPair;
    final priQ = PriorityQueue<BoundablePair>();
    priQ.add(initBndPair);
    while ((priQ.isNotEmpty) && (distanceLowerBound > 0.0)) {
      BoundablePair bndPair = priQ.removeFirst();
      double pairDistance = bndPair.getDistance();
      if (pairDistance >= distanceLowerBound) {
        break;
      }

      if (bndPair.isLeaves()) {
        distanceLowerBound = pairDistance;
        minPair = bndPair;
      } else {
        bndPair.expandToQueue(priQ, distanceLowerBound);
      }
    }
    if (minPair == null) {
      return null;
    }

    return [
      (minPair.getBoundable(0) as ItemBoundable<T, Envelope>).item,
      (minPair.getBoundable(1) as ItemBoundable<T, Envelope>).item,
    ].toArray();
  }

  bool isWithinDistance(
      STRtree tree, ItemDistance itemDist, double maxDistance) {
    final bp = BoundablePair(getRoot(), tree.getRoot(), itemDist);
    return isWithinDistance2(bp, maxDistance);
  }

  bool isWithinDistance2(
      BoundablePair<Envelope> initBndPair, double maxDistance) {
    double distanceUpperBound = double.infinity;
    final priQ = PriorityQueue<BoundablePair>();
    priQ.add(initBndPair);
    while (priQ.isNotEmpty) {
      BoundablePair bndPair = priQ.removeFirst();
      double pairDistance = bndPair.getDistance();
      if (pairDistance > maxDistance) {
        return false;
      }

      if (bndPair.maximumDistance() <= maxDistance) {
        return true;
      }

      if (bndPair.isLeaves()) {
        distanceUpperBound = pairDistance;
        if (distanceUpperBound <= maxDistance) {
          return true;
        }
      } else {
        bndPair.expandToQueue(priQ, distanceUpperBound);
      }
    }
    return false;
  }

  Array<Object> nearestNeighbour3(
      Envelope env, T item, ItemDistance itemDist, int k) {
    if (isEmpty()) return Array(0);

    final bnd = ItemBoundable(env, item);
    final bp = BoundablePair<Envelope>(getRoot(), bnd, itemDist);
    return nearestNeighbourK2(bp, k);
  }

  Array<Object> nearestNeighbourK2(BoundablePair<Envelope> initBndPair, int k) {
    return nearestNeighbourK(initBndPair, double.infinity, k);
  }

  Array<Object> nearestNeighbourK(
      BoundablePair<Envelope> initBndPair, double maxDistance, int k) {
    double distanceLowerBound = maxDistance;
    final priQ = PriorityQueue<BoundablePair<Envelope>>();
    priQ.add(initBndPair);
    final kNearestNeighbors = PriorityQueue<BoundablePair<Envelope>>();
    while ((priQ.isNotEmpty) && (distanceLowerBound >= 0.0)) {
      final bndPair = priQ.removeFirst();
      double pairDistance = bndPair.getDistance();
      if (pairDistance >= distanceLowerBound) {
        break;
      }
      if (bndPair.isLeaves()) {
        if (kNearestNeighbors.length < k) {
          kNearestNeighbors.add(bndPair);
        } else {
          BoundablePair bp1 = kNearestNeighbors.first;
          if (bp1.getDistance() > pairDistance) {
            kNearestNeighbors.removeFirst();
            kNearestNeighbors.add(bndPair);
          }
          BoundablePair bp2 = kNearestNeighbors.first;
          distanceLowerBound = bp2.getDistance();
        }
      } else {
        bndPair.expandToQueue(priQ, distanceLowerBound);
      }
    }
    return getItems(kNearestNeighbors);
  }

  static Array<Object> getItems(
      PriorityQueue<BoundablePair<Envelope>> kNearestNeighbors) {
    Array<Object> items = Array(kNearestNeighbors.length);
    int count = 0;
    while (kNearestNeighbors.isNotEmpty) {
      BoundablePair bp = kNearestNeighbors.removeFirst();
      items[count] = (bp.getBoundable(0) as ItemBoundable).item;
      count++;
    }
    return items;
  }
}

final class STRtreeNode extends AbstractNode<Envelope> {
  STRtreeNode(super.level);

  @override
  Envelope computeBounds() {
    Envelope? bounds;
    for (var childBoundable in getChildBoundables()) {
      if (bounds == null) {
        bounds = Envelope.from(childBoundable.getBounds());
      } else {
        bounds.expandToInclude(childBoundable.getBounds());
      }
    }
    return bounds!;
  }
}
