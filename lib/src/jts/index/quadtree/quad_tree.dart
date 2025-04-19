import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/index/array_list_visitor.dart';
import 'package:dts/src/jts/index/item_visitor.dart';
import 'package:dts/src/jts/index/spatial_index.dart';
import 'package:dts/src/jts/util/assert.dart';

import '../../geom/coordinate.dart';
import '../Interval_size.dart';
import 'double_bits.dart';

class Quadtree<T> implements SpatialIndex<T> {
  static Envelope ensureExtent(Envelope itemEnv, double minExtent) {
    double minx = itemEnv.minX;
    double maxx = itemEnv.maxX;
    double miny = itemEnv.minY;
    double maxy = itemEnv.maxY;
    if ((minx != maxx) && (miny != maxy)) {
      return itemEnv;
    }

    if (minx == maxx) {
      minx = minx - (minExtent / 2.0);
      maxx = maxx + (minExtent / 2.0);
    }
    if (miny == maxy) {
      miny = miny - (minExtent / 2.0);
      maxy = maxy + (minExtent / 2.0);
    }
    return Envelope.fromLRTB(minx, maxx, miny, maxy);
  }

  Root<T>? _root;

  double minExtent = 1.0;

  Quadtree() {
    _root = Root();
  }

  int depth() {
    if (_root != null) return _root!.depth();

    return 0;
  }

  bool isEmpty() {
    if (_root == null) {
      return true;
    }

    return _root!.isEmpty();
  }

  int size() {
    if (_root != null) return _root!.size();

    return 0;
  }

  @override
  void insert(Envelope itemEnv, T item) {
    collectStats(itemEnv);
    Envelope insertEnv = ensureExtent(itemEnv, minExtent);
    _root!.insert(insertEnv, item);
  }

  @override
  bool remove(Envelope itemEnv, T item) {
    Envelope posEnv = ensureExtent(itemEnv, minExtent);
    return _root!.remove(posEnv, item);
  }

  @override
  List<T> query(Envelope searchEnv) {
    final visitor = ArrayListVisitor<T>();
    each(searchEnv, visitor);
    return visitor.getItems();
  }

  @override
  void each(Envelope searchEnv, ItemVisitor<T> visitor) {
    _root!.visit(searchEnv, visitor);
  }

  List<T> queryAll() {
    List<T> foundItems = [];
    _root!.addAllItems(foundItems);
    return foundItems;
  }

  void collectStats(Envelope itemEnv) {
    double delX = itemEnv.width;
    if ((delX < minExtent) && (delX > 0.0)) {
      minExtent = delX;
    }

    double delY = itemEnv.height;
    if ((delY < minExtent) && (delY > 0.0)) {
      minExtent = delY;
    }
  }

  Root<T>? getRoot() {
    return _root;
  }
}

abstract class NodeBase<T> {
  static int getSubnodeIndex(Envelope env, double centreX, double centreY) {
    int subnodeIndex = -1;
    if (env.minX >= centreX) {
      if (env.minY >= centreY) subnodeIndex = 3;

      if (env.maxY <= centreY) {
        subnodeIndex = 1;
      }
    }
    if (env.maxX <= centreX) {
      if (env.minY >= centreY) {
        subnodeIndex = 2;
      }

      if (env.maxY <= centreY) {
        subnodeIndex = 0;
      }
    }
    return subnodeIndex;
  }

  final List<T> _items = [];

  Array<QuadNode<T>?> subnode = Array(4);

  List<T> get items => _items;

  bool hasItems() {
    return _items.isEmpty;
  }

  void add(T item) {
    _items.add(item);
  }

  List<T> addAllItems(List<T> resultItems) {
    resultItems.addAll(_items);
    for (int i = 0; i < 4; i++) {
      subnode[i]?.addAllItems(resultItems);
    }
    return resultItems;
  }

  bool remove(Envelope itemEnv, T item) {
    if (!isSearchMatch(itemEnv)) {
      return false;
    }

    bool found = false;
    for (int i = 0; i < 4; i++) {
      if (subnode.get(i) != null) {
        found = subnode[i]!.remove(itemEnv, item);
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

    found = _items.remove(item);
    return found;
  }

  bool isPrunable() {
    return !(hasChildren() || hasItems());
  }

  bool hasChildren() {
    for (int i = 0; i < 4; i++) {
      if (subnode.get(i) != null) {
        return true;
      }
    }
    return false;
  }

  bool isEmpty() {
    bool isEmpty = true;
    if (_items.isNotEmpty) {
      isEmpty = false;
    } else {
      for (int i = 0; i < 4; i++) {
        if (subnode.get(i) != null) {
          if (!subnode[i]!.isEmpty()) {
            isEmpty = false;
            break;
          }
        }
      }
    }
    return isEmpty;
  }

  bool isSearchMatch(Envelope searchEnv);

  void addAllItemsFromOverlapping(Envelope searchEnv, List<T> resultItems) {
    if (!isSearchMatch(searchEnv)) return;

    resultItems.addAll(_items);
    for (int i = 0; i < 4; i++) {
      subnode[i]?.addAllItemsFromOverlapping(searchEnv, resultItems);
    }
  }

  void visit(Envelope searchEnv, ItemVisitor<T> visitor) {
    if (!isSearchMatch(searchEnv)) return;
    visitItems(searchEnv, visitor);
    for (int i = 0; i < 4; i++) {
      subnode[i]?.visit(searchEnv, visitor);
    }
  }

  void visitItems(Envelope searchEnv, ItemVisitor<T> visitor) {
    for (int i = 0; i < _items.size; i++) {
      visitor.visitItem(_items.get(i));
    }
  }

  int depth() {
    int maxSubDepth = 0;
    for (int i = 0; i < 4; i++) {
      if (subnode.get(i) != null) {
        int sqd = subnode[i]!.depth();
        if (sqd > maxSubDepth) maxSubDepth = sqd;
      }
    }
    return maxSubDepth + 1;
  }

  int size() {
    int subSize = 0;
    for (int i = 0; i < 4; i++) {
      subSize += subnode[i]!.size();
    }
    return subSize + _items.size;
  }

  int getNodeCount() {
    int subSize = 0;
    for (int i = 0; i < 4; i++) {
      if (subnode.get(i) != null) {
        subSize += subnode[i]!.size();
      }
    }
    return subSize + 1;
  }
}

class Root<T> extends NodeBase<T> {
  static final Coordinate _origin = Coordinate(0.0, 0.0);

  void insert(Envelope itemEnv, T item) {
    int index = NodeBase.getSubnodeIndex(itemEnv, _origin.x, _origin.y);
    if (index == (-1)) {
      add(item);
      return;
    }
    final node = subnode.get(index);
    if ((node == null) || (!node.getEnvelope().contains(itemEnv))) {
      final largerNode = QuadNode.createExpanded(node, itemEnv);
      subnode[index] = largerNode;
    }
    insertContained(subnode[index]!, itemEnv, item);
  }

  void insertContained(QuadNode<T> tree, Envelope itemEnv, T item) {
    Assert.isTrue(tree.getEnvelope().contains(itemEnv));
    bool isZeroX = IntervalSize.isZeroWidth(itemEnv.minX, itemEnv.maxX);
    bool isZeroY = IntervalSize.isZeroWidth(itemEnv.minY, itemEnv.maxY);
    NodeBase node;
    if (isZeroX || isZeroY) {
      node = tree.find(itemEnv);
    } else {
      node = tree.getNode(itemEnv);
    }
    node.add(item);
  }

  @override
  bool isSearchMatch(Envelope searchEnv) {
    return true;
  }
}

class QuadNode<T> extends NodeBase<T> {
  static QuadNode<T> createNode<T>(Envelope env) {
    _Key key = _Key(env);
    return QuadNode(key.getEnvelope(), key.getLevel());
  }

  static QuadNode<T> createExpanded<T>(QuadNode<T>? node, Envelope addEnv) {
    Envelope expandEnv = Envelope.from(addEnv);
    if (node != null) {
      expandEnv.expandToInclude(node.env);
    }

    final largerNode = createNode<T>(expandEnv);
    if (node != null) {
      largerNode.insertNode(node);
    }

    return largerNode;
  }

  Envelope env;

  double _centrex = 0;

  double _centrey = 0;

  int level;

  QuadNode(this.env, this.level) {
    _centrex = (env.minX + env.maxX) / 2;
    _centrey = (env.minY + env.maxY) / 2;
  }

  Envelope getEnvelope() {
    return env;
  }

  @override
  bool isSearchMatch(Envelope? searchEnv) {
    if (searchEnv == null) {
      return false;
    }

    return env.intersects(searchEnv);
  }

  QuadNode<T> getNode(Envelope searchEnv) {
    int subnodeIndex = NodeBase.getSubnodeIndex(searchEnv, _centrex, _centrey);
    if (subnodeIndex != (-1)) {
      final node = getSubnode(subnodeIndex);
      return node.getNode(searchEnv);
    } else {
      return this;
    }
  }

  NodeBase<T> find(Envelope searchEnv) {
    int subnodeIndex = NodeBase.getSubnodeIndex(searchEnv, _centrex, _centrey);
    if (subnodeIndex == (-1)) {
      return this;
    }

    if (subnode.get(subnodeIndex) != null) {
      final node = subnode[subnodeIndex];
      return node!.find(searchEnv);
    }
    return this;
  }

  void insertNode(QuadNode<T> node) {
    Assert.isTrue(env.contains(node.env));
    int index = NodeBase.getSubnodeIndex(node.env, _centrex, _centrey);
    if (node.level == (level - 1)) {
      subnode[index] = node;
    } else {
      final childNode = createSubnode(index);
      childNode.insertNode(node);
      subnode[index] = childNode;
    }
  }

  QuadNode<T> getSubnode(int index) {
    if (subnode.get(index) == null) {
      subnode[index] = createSubnode(index);
    }
    return subnode[index]!;
  }

  QuadNode<T> createSubnode(int index) {
    double minx = 0.0;
    double maxx = 0.0;
    double miny = 0.0;
    double maxy = 0.0;
    switch (index) {
      case 0:
        minx = env.minX;
        maxx = _centrex;
        miny = env.minY;
        maxy = _centrey;
        break;
      case 1:
        minx = _centrex;
        maxx = env.maxX;
        miny = env.minY;
        maxy = _centrey;
        break;
      case 2:
        minx = env.minX;
        maxx = _centrex;
        miny = _centrey;
        maxy = env.maxY;
        break;
      case 3:
        minx = _centrex;
        maxx = env.maxX;
        miny = _centrey;
        maxy = env.maxY;
        break;
    }
    Envelope sqEnv = Envelope.fromLRTB(minx, maxx, miny, maxy);
    return QuadNode(sqEnv, level - 1);
  }

  int getLevel() {
    return level;
  }
}

class _Key {
  static int computeQuadLevel(Envelope env) {
    double dx = env.width;
    double dy = env.height;
    double dMax = (dx > dy) ? dx : dy;
    int level = DoubleBits.exponent(dMax) + 1;
    return level;
  }

  final _pt = Coordinate();

  int level = 0;

  late Envelope env;

  _Key(Envelope itemEnv) {
    computeKey(itemEnv);
  }

  Coordinate getPoint() {
    return _pt;
  }

  int getLevel() {
    return level;
  }

  Envelope getEnvelope() {
    return env;
  }

  Coordinate getCentre() => env.centre()!;

  void computeKey(Envelope itemEnv) {
    level = computeQuadLevel(itemEnv);
    env = Envelope();
    computeKey2(level, itemEnv);
    while (!env.contains(itemEnv)) {
      level += 1;
      computeKey2(level, itemEnv);
    }
  }

  void computeKey2(int level, Envelope itemEnv) {
    double quadSize = DoubleBits.powerOf2(level);
    _pt.x = Math.floor(itemEnv.minX / quadSize) * quadSize;
    _pt.y = Math.floor(itemEnv.minY / quadSize) * quadSize;
    env.initWithLRTB(_pt.x, _pt.x + quadSize, _pt.y, _pt.y + quadSize);
  }
}
