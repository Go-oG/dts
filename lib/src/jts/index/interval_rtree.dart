import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/index/item_visitor.dart';

class SortedPackedIntervalRTree<T> {
  final List<IntervalRTreeLeafNode<T>> _leaves = [];

  IntervalRTreeNode<T>? _root;

  SortedPackedIntervalRTree();

  void insert(double min, double max, T item) {
    if (_root != null) {
      throw ("Index cannot be added to once it has been queried");
    }

    _leaves.add(IntervalRTreeLeafNode(min, max, item));
  }

  void init() {
    if (_root != null) {
      return;
    }

    if (_leaves.isEmpty) return;

    buildRoot();
  }

  void buildRoot() {
    if (_root != null) {
      return;
    }

    _root = buildTree();
  }

  IntervalRTreeNode<T> buildTree() {
    var cc = NodeComparator<T>();
    _leaves.sort(cc.compare);

    List<IntervalRTreeNode<T>> src = _leaves;
    List<IntervalRTreeNode<T>> temp = [];
    List<IntervalRTreeNode<T>> dest = [];
    while (true) {
      buildLevel(src, dest);
      if (dest.size == 1) return dest.first;

      temp = src;
      src = dest;
      dest = temp;
    }
  }

  void buildLevel(List<IntervalRTreeNode<T>> src, List<IntervalRTreeNode<T>> dest) {
    dest.clear();
    for (int i = 0; i < src.size; i += 2) {
      final n1 = src[i];
      final n2 = ((i + 1) < src.size) ? src[i] : null;
      if (n2 == null) {
        dest.add(n1);
      } else {
        final node = IntervalRTreeBranchNode<T>(src.get(i), src.get(i + 1));
        dest.add(node);
      }
    }
  }

  void query(double min, double max, ItemVisitor<T> visitor) {
    init();
    if (_root == null) {
      return;
    }

    _root!.query(min, max, visitor);
  }
}

abstract class IntervalRTreeNode<T> {
  double min = double.infinity;
  double max = double.negativeInfinity;

  void query(double queryMin, double queryMax, ItemVisitor<T> visitor);

  bool intersects(double queryMin, double queryMax) {
    if ((min > queryMax) || (max < queryMin)) return false;
    return true;
  }
}

class NodeComparator<T> implements CComparator<IntervalRTreeNode<T>> {
  @override
  int compare(IntervalRTreeNode<T> n1, IntervalRTreeNode<T> n2) {
    double mid1 = (n1.min + n1.max) / 2;
    double mid2 = (n2.min + n2.max) / 2;
    if (mid1 < mid2) return -1;

    if (mid1 > mid2) return 1;

    return 0;
  }
}

class IntervalRTreeLeafNode<T> extends IntervalRTreeNode<T> {
  T item;

  IntervalRTreeLeafNode(double min, double max, this.item) {
    this.min = min;
    this.max = max;
  }

  @override
  void query(double queryMin, double queryMax, ItemVisitor<T> visitor) {
    if (!intersects(queryMin, queryMax)) {
      return;
    }
    visitor.visitItem(item);
  }
}

class IntervalRTreeBranchNode<T> extends IntervalRTreeNode<T> {
  final IntervalRTreeNode _node1;
  final IntervalRTreeNode _node2;

  IntervalRTreeBranchNode(this._node1, this._node2) {
    buildExtent(_node1, _node2);
  }

  void buildExtent(IntervalRTreeNode n1, IntervalRTreeNode n2) {
    min = Math.minD(n1.min, n2.min);
    max = Math.maxD(n1.max, n2.max);
  }

  @override
  void query(double queryMin, double queryMax, ItemVisitor visitor) {
    if (!intersects(queryMin, queryMax)) {
      return;
    }

    _node1.query(queryMin, queryMax, visitor);
    _node2.query(queryMin, queryMax, visitor);
  }
}
