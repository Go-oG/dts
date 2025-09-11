import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/index/quadtree/double_bits.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'interval_size.dart';

class BinTree<T> {
  static BinInterval ensureExtent(BinInterval itemInterval, double minExtent) {
    double min = itemInterval.getMin();
    double max = itemInterval.getMax();
    if (min != max) {
      return itemInterval;
    }
    if (min == max) {
      min = min - (minExtent / 2.0);
      max = min + (minExtent / 2.0);
    }
    return BinInterval(min, max);
  }

  _Root? _root;

  double _minExtent = 1.0;

  BinTree() {
    _root = _Root();
  }

  int depth() {
    if (_root != null) return _root!.depth();

    return 0;
  }

  int size() {
    if (_root != null) return _root!.size();

    return 0;
  }

  int nodeSize() {
    if (_root != null) return _root!.nodeSize();

    return 0;
  }

  void insert(BinInterval itemInterval, T item) {
    collectStats(itemInterval);
    BinInterval insertInterval = ensureExtent(itemInterval, _minExtent);
    _root!.insert(insertInterval, item);
  }

  bool remove(BinInterval itemInterval, T item) {
    BinInterval insertInterval = ensureExtent(itemInterval, _minExtent);
    return _root!.remove(insertInterval, item);
  }

  List<T> iterator() {
    List<T> foundItems = [];
    _root!.addAllItems(foundItems);
    return foundItems;
  }

  List<T> query(double x) {
    return query2(BinInterval(x, x));
  }

  List<T> query2(BinInterval interval) {
    List<T> foundItems = [];
    query3(interval, foundItems);
    return foundItems;
  }

  void query3(BinInterval interval, List<T> foundItems) {
    _root!.addAllItemsFromOverlapping(interval, foundItems);
  }

  void collectStats(BinInterval interval) {
    double del = interval.getWidth();
    if ((del < _minExtent) && (del > 0.0)) {
      _minExtent = del;
    }
  }
}

class _Key {
  static int computeLevel(BinInterval interval) {
    double dx = interval.getWidth();
    int level = DoubleBits.exponent(dx) + 1;
    return level;
  }

  double _pt = 0.0;

  int _level = 0;

  late BinInterval _interval;

  _Key(BinInterval interval) {
    computeKey(interval);
  }

  double getPoint() {
    return _pt;
  }

  int getLevel() {
    return _level;
  }

  BinInterval getInterval() {
    return _interval;
  }

  void computeKey(BinInterval itemInterval) {
    _level = computeLevel(itemInterval);
    _interval = BinInterval.empty();
    computeInterval(_level, itemInterval);
    while (!_interval.contains2(itemInterval)) {
      _level += 1;
      computeInterval(_level, itemInterval);
    }
  }

  void computeInterval(int level, BinInterval itemInterval) {
    double size = DoubleBits.powerOf2(level);
    _pt = Math.floor(itemInterval.getMin() / size) * size;
    _interval.init(_pt, _pt + size);
  }
}

class BinInterval {
  double min = 0;

  double max = 0;

  BinInterval.empty() {
    min = 0.0;
    max = 0.0;
  }

  BinInterval(double min, double max) {
    init(min, max);
  }

  BinInterval.of(BinInterval interval) {
    init(interval.min, interval.max);
  }

  void init(double min, double max) {
    this.min = min;
    this.max = max;
    if (min > max) {
      this.min = max;
      this.max = min;
    }
  }

  double getMin() {
    return min;
  }

  double getMax() {
    return max;
  }

  double getWidth() {
    return max - min;
  }

  void expandToInclude(BinInterval interval) {
    if (interval.max > max) {
      max = interval.max;
    }

    if (interval.min < min) {
      min = interval.min;
    }
  }

  bool overlaps(BinInterval interval) {
    return overlaps2(interval.min, interval.max);
  }

  bool overlaps2(double min, double max) {
    return (!(this.min > max)) && (!(this.max < min));
  }

  bool contains(double p) {
    return (p >= min) && (p <= max);
  }

  bool contains2(BinInterval interval) {
    return contains3(interval.min, interval.max);
  }

  bool contains3(double min, double max) {
    return (min >= this.min) && (max <= this.max);
  }
}

abstract class _NodeBase<T> {
  static int getSubnodeIndex(BinInterval interval, double centre) {
    int subnodeIndex = -1;
    if (interval.min >= centre) subnodeIndex = 1;

    if (interval.max <= centre) {
      subnodeIndex = 0;
    }

    return subnodeIndex;
  }

  List<T> items = [];

  Array<BinNode<T>?> subnode = Array(2);

  List getItems() {
    return items;
  }

  void add(T item) {
    items.add(item);
  }

  List<T> addAllItems(List<T> items) {
    items.addAll(this.items);
    for (int i = 0; i < 2; i++) {
      subnode[i]?.addAllItems(items);
    }
    return items;
  }

  bool isSearchMatch(BinInterval interval);

  void addAllItemsFromOverlapping(BinInterval? interval, List<T> resultItems) {
    if ((interval != null) && (!isSearchMatch(interval))) return;

    resultItems.addAll(items);
    subnode[0]?.addAllItemsFromOverlapping(interval, resultItems);
    subnode[1]?.addAllItemsFromOverlapping(interval, resultItems);
  }

  bool remove(BinInterval itemInterval, T item) {
    if (!isSearchMatch(itemInterval)) return false;

    bool found = false;
    for (int i = 0; i < 2; i++) {
      if (subnode.get(i) != null) {
        found = subnode[i]!.remove(itemInterval, item);
        if (found) {
          if (subnode[i]!.isPrunable()) {
            subnode[i] = null;
          }
          break;
        }
      }
    }
    if (found) {
      return found;
    }

    return items.remove(item);
  }

  bool isPrunable() {
    return !(hasChildren() || hasItems());
  }

  bool hasChildren() {
    for (int i = 0; i < 2; i++) {
      if (subnode.get(i) != null) return true;
    }
    return false;
  }

  bool hasItems() {
    return items.isNotEmpty;
  }

  int depth() {
    int maxSubDepth = 0;
    for (int i = 0; i < 2; i++) {
      if (subnode.get(i) != null) {
        int sqd = subnode[i]!.depth();
        if (sqd > maxSubDepth) maxSubDepth = sqd;
      }
    }
    return maxSubDepth + 1;
  }

  int size() {
    int subSize = 0;
    for (int i = 0; i < 2; i++) {
      if (subnode.get(i) != null) {
        subSize += subnode[i]!.size();
      }
    }
    return subSize + items.size;
  }

  int nodeSize() {
    int subSize = 0;
    for (int i = 0; i < 2; i++) {
      if (subnode.get(i) != null) {
        subSize += subnode[i]!.nodeSize();
      }
    }
    return subSize + 1;
  }
}

class BinNode<T> extends _NodeBase<T> {
  static BinNode<T> createNode<T>(BinInterval itemInterval) {
    _Key key = _Key(itemInterval);
    return BinNode(key.getInterval(), key.getLevel());
  }

  static BinNode<T> createExpanded<T>(BinNode<T>? node, BinInterval addInterval) {
    BinInterval expandInt = BinInterval.of(addInterval);
    if (node != null) expandInt.expandToInclude(node.interval);

    BinNode<T> largerNode = createNode(expandInt);
    if (node != null) {
      largerNode.insert(node);
    }

    return largerNode;
  }

  BinInterval interval;

  double _centre = 0;

  final int _level;

  BinNode(this.interval, this._level) {
    _centre = (interval.getMin() + interval.getMax()) / 2;
  }

  BinInterval getInterval() {
    return interval;
  }

  @override
  bool isSearchMatch(BinInterval itemInterval) {
    return itemInterval.overlaps(interval);
  }

  BinNode<T> getNode(BinInterval searchInterval) {
    int subnodeIndex = _NodeBase.getSubnodeIndex(searchInterval, _centre);
    if (subnodeIndex != (-1)) {
      BinNode<T> node = getSubnode(subnodeIndex);
      return node.getNode(searchInterval);
    } else {
      return this;
    }
  }

  BinNode<T> find(BinInterval searchInterval) {
    int subnodeIndex = _NodeBase.getSubnodeIndex(searchInterval, _centre);
    if (subnodeIndex == (-1)) return this;
    if (subnode.get(subnodeIndex) != null) {
      final node = subnode[subnodeIndex];
      return node!.find(searchInterval);
    }
    return this;
  }

  void insert(BinNode<T> node) {
    Assert.isTrue(interval.contains2(node.interval));
    int index = _NodeBase.getSubnodeIndex(node.interval, _centre);
    if (node._level == (_level - 1)) {
      subnode[index] = node;
    } else {
      final childNode = createSubnode(index);
      childNode.insert(node);
      subnode[index] = childNode;
    }
  }

  BinNode<T> getSubnode(int index) {
    if (subnode.get(index) == null) {
      subnode[index] = createSubnode(index);
    }
    return subnode[index]!;
  }

  BinNode<T> createSubnode(int index) {
    double min = 0.0;
    double max = 0.0;
    switch (index) {
      case 0:
        min = interval.getMin();
        max = _centre;
        break;
      case 1:
        min = _centre;
        max = interval.getMax();
        break;
    }
    BinInterval subInt = BinInterval(min, max);
    return BinNode(subInt, _level - 1);
  }
}

class _Root<T> extends _NodeBase<T> {
  static const double _origin = 0.0;

  void insert(BinInterval itemInterval, T item) {
    int index = _NodeBase.getSubnodeIndex(itemInterval, _origin);
    if (index == (-1)) {
      add(item);
      return;
    }
    final node = subnode.get(index);
    if ((node == null) || (!node.getInterval().contains2(itemInterval))) {
      subnode[index] = BinNode.createExpanded<T>(node, itemInterval);
    }
    insertContained(subnode[index]!, itemInterval, item);
  }

  void insertContained(BinNode tree, BinInterval itemInterval, T item) {
    Assert.isTrue(tree.getInterval().contains2(itemInterval));
    bool isZeroArea = IntervalSize.isZeroWidth(itemInterval.getMin(), itemInterval.getMax());
    _NodeBase node;
    if (isZeroArea) {
      node = tree.find(itemInterval);
    } else {
      node = tree.getNode(itemInterval);
    }

    node.add(item);
  }

  @override
  bool isSearchMatch(BinInterval interval) {
    return true;
  }
}
