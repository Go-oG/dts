import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/index/item_visitor.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'abstract_node.dart';
import 'boundable.dart';

abstract class AbstractSTRtree<T, B> {
  AbstractNode<B>? root;

  bool _built = false;

  List<Boundable<B>>? _itemBoundables = [];

  int _nodeCapacity = 10;

  AbstractSTRtree([int nodeCapacity = 10]) {
    Assert.isTrue(nodeCapacity > 1, "Node capacity must be greater than 1");
    _nodeCapacity = nodeCapacity;
  }

  AbstractSTRtree.of(int nodeCapacity, this.root) {
    _nodeCapacity = nodeCapacity;
    _built = true;
    _itemBoundables = null;
  }

  AbstractSTRtree.of2(int nodeCapacity, List<Boundable<B>>? itemBoundables) {
    _nodeCapacity = nodeCapacity;
    _itemBoundables = itemBoundables;
  }

  void build() {
    if (_built) {
      return;
    }

    root = _itemBoundables!.isEmpty ? createNode(0) : createHigherLevels(_itemBoundables!, -1);
    _itemBoundables = null;
    _built = true;
  }

  AbstractNode<B> createNode(int level);

  List<AbstractNode<B>> createParentBoundables(List<Boundable<B>> childBoundables, int newLevel) {
    Assert.isTrue(childBoundables.isNotEmpty);
    List<AbstractNode<B>> parentBoundables = [];
    parentBoundables.add(createNode(newLevel));
    final List<Boundable<B>> sortedChildBoundables = List.from(childBoundables);
    sortedChildBoundables.sort(getComparator().compare);

    for (var childBoundable in sortedChildBoundables) {
      if (lastNode(parentBoundables).getChildBoundables().size == getNodeCapacity()) {
        parentBoundables.add(createNode(newLevel));
      }
      lastNode(parentBoundables).addChildBoundable(childBoundable);
    }
    return parentBoundables;
  }

  AbstractNode<B> lastNode(List<AbstractNode<B>> nodes) {
    return nodes.last;
  }

  static int compareDoubles(double a, double b) {
    return a > b
        ? 1
        : a < b
            ? -1
            : 0;
  }

  AbstractNode<B> createHigherLevels(List<Boundable<B>> boundablesOfALevel, int level) {
    Assert.isTrue(boundablesOfALevel.isNotEmpty);
    final parentBoundables = createParentBoundables(boundablesOfALevel, level + 1);
    if (parentBoundables.size == 1) {
      return parentBoundables.get(0);
    }
    return createHigherLevels(parentBoundables, level + 1);
  }

  AbstractNode<B> getRoot() {
    build();
    return root!;
  }

  int getNodeCapacity() {
    return _nodeCapacity;
  }

  bool isEmpty() {
    if (!_built) return _itemBoundables!.isEmpty;

    return root!.isEmpty();
  }

  int size() {
    if (isEmpty()) {
      return 0;
    }
    build();
    return size2(root!);
  }

  int size2(AbstractNode<B> node) {
    int size = 0;
    for (var childBoundable in node.getChildBoundables()) {
      if (childBoundable is AbstractNode<B>) {
        size += size2(childBoundable);
      } else if (childBoundable is ItemBoundable) {
        size += 1;
      }
    }
    return size;
  }

  int depth() {
    if (isEmpty()) {
      return 0;
    }
    build();
    return depth2(root!);
  }

  int depth2(AbstractNode<B> node) {
    int maxChildDepth = 0;
    for (var childBoundable in node.getChildBoundables()) {
      if (childBoundable is AbstractNode<B>) {
        int childDepth = depth2(childBoundable);
        if (childDepth > maxChildDepth) maxChildDepth = childDepth;
      }
    }
    return maxChildDepth + 1;
  }

  void insert(B bounds, T item) {
    Assert.isTrue(!_built, "Cannot insert items into an STR packed R-tree after it has been built.");
    _itemBoundables!.add(ItemBoundable(bounds, item));
  }

  List<T> query(B searchBounds) {
    build();
    List<T> matches = [];
    if (isEmpty()) {
      return matches;
    }
    if (getIntersectsOp().intersects(root!.getBounds(), searchBounds)) {
      queryInternal(searchBounds, root!, matches);
    }

    return matches;
  }

  void query2(B searchBounds, ItemVisitor<T> visitor) {
    build();
    if (isEmpty()) {
      return;
    }
    if (getIntersectsOp().intersects(root!.getBounds(), searchBounds)) {
      eachInternal(searchBounds, root!, visitor);
    }
  }

  IntersectsOp<B> getIntersectsOp();

  void queryInternal(B searchBounds, AbstractNode node, List<T> matches) {
    final childBoundables = node.getChildBoundables();
    for (var childBoundable in childBoundables) {
      if (!getIntersectsOp().intersects(childBoundable.getBounds(), searchBounds)) {
        continue;
      }
      if (childBoundable is AbstractNode) {
        queryInternal(searchBounds, childBoundable, matches);
      } else if (childBoundable is ItemBoundable) {
        matches.add(childBoundable.item);
      } else {
        Assert.shouldNeverReachHere();
      }
    }
  }

  void eachInternal(B searchBounds, AbstractNode node, ItemVisitor<T> visitor) {
    final childBoundables = node.getChildBoundables();
    for (var childBoundable in childBoundables) {
      if (!getIntersectsOp().intersects(childBoundable.getBounds(), searchBounds)) {
        continue;
      }
      if (childBoundable is AbstractNode) {
        eachInternal(searchBounds, childBoundable, visitor);
      } else if (childBoundable is ItemBoundable) {
        visitor.visitItem(childBoundable.item);
      } else {
        Assert.shouldNeverReachHere();
      }
    }
  }

  List<T>? itemsTree([AbstractNode? node]) {
    if (node == null) {
      build();
      node = root!;
    }
    List<T> valuesTreeForNode = [];
    for (var childBoundable in node.getChildBoundables()) {
      if (childBoundable is AbstractNode) {
        final valuesTreeForChild = itemsTree(childBoundable);
        if (valuesTreeForChild != null) {
          valuesTreeForNode.addAll(valuesTreeForChild);
        }
      } else if (childBoundable is ItemBoundable) {
        valuesTreeForNode.add(childBoundable.item);
      } else {
        Assert.shouldNeverReachHere();
      }
    }
    if (valuesTreeForNode.size <= 0) {
      return null;
    }
    return valuesTreeForNode;
  }

  bool remove(B searchBounds, T item) {
    build();
    if (getIntersectsOp().intersects(root!.getBounds(), searchBounds)) {
      return remove2(searchBounds, root!, item);
    }
    return false;
  }

  bool removeItem(AbstractNode<B> node, T item) {
    Boundable? childToRemove;
    for (var childBoundable in node.getChildBoundables()) {
      if (childBoundable is ItemBoundable) {
        if ((childBoundable as ItemBoundable).item == item) {
          childToRemove = childBoundable;
        }
      }
    }

    if (childToRemove != null) {
      node.getChildBoundables().remove(childToRemove);
      return true;
    }
    return false;
  }

  bool remove2(B searchBounds, AbstractNode<B> node, T item) {
    bool found = removeItem(node, item);
    if (found) {
      return true;
    }

    AbstractNode<B>? childToPrune;
    for (var childBoundable in node.getChildBoundables()) {
      if (!getIntersectsOp().intersects(childBoundable.getBounds(), searchBounds)) {
        continue;
      }
      if (childBoundable is AbstractNode<B>) {
        found = remove2(searchBounds, childBoundable, item);
        if (found) {
          childToPrune = childBoundable;
          break;
        }
      }
    }

    if (childToPrune != null) {
      if (childToPrune.getChildBoundables().isEmpty) {
        node.getChildBoundables().remove(childToPrune);
      }
    }
    return found;
  }

  List<Boundable<B>> boundablesAtLevel(int level) {
    List<Boundable<B>> boundables = [];
    boundablesAtLevel2(level, root!, boundables);
    return boundables;
  }

  void boundablesAtLevel2(int level, AbstractNode<B> top, List<Boundable<B>> boundables) {
    Assert.isTrue(level > (-2));
    if (top.level == level) {
      boundables.add(top);
      return;
    }
    for (var boundable in top.getChildBoundables()) {
      if (boundable is AbstractNode<B>) {
        boundablesAtLevel2(level, boundable, boundables);
      } else {
        Assert.isTrue(boundable is ItemBoundable<T, B>);
        if (level == (-1)) {
          boundables.add(boundable);
        }
      }
    }
    return;
  }

  CComparator<Boundable<B>> getComparator();

  List<Boundable<B>> getItemBoundables() => _itemBoundables ?? [];
}

abstract interface class IntersectsOp<B> {
  bool intersects(B aBounds, B bBounds);
}

class IntersectsOp2<B> implements IntersectsOp<B> {
  final bool Function(B a, B b) callFun;

  IntersectsOp2(this.callFun);

  @override
  bool intersects(B aBounds, B bBounds) {
    return callFun(aBounds, bBounds);
  }
}
