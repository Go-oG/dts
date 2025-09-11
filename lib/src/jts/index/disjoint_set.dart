class DisjointSet<T> {
  DisjointSet._();

  static Item<T> makeSet<T>(T v) {
    final Item<T> item = Item<T>(null, v);
    item.parent = item;
    return item;
  }

  static Item<T>? find<T>(Item<T>? x) {
    if (x == null) return null;

    if (x.parent != null && x.parent != x) {
      return x.parent = find(x.parent);
    }
    return x.parent;
  }

  Item<T>? union(Item<T> x, Item<T> y) {
    final Item<T>? xRoot = find(x);
    final Item<T>? yRoot = find(y);
    if (xRoot == null && yRoot == null) return null;
    if (xRoot == null && yRoot != null) return yRoot;
    if (yRoot == null && xRoot != null) return xRoot;

    if (xRoot == yRoot) return xRoot;

    if (xRoot!.rank < yRoot!.rank) {
      xRoot.parent = yRoot;
      return yRoot;
    } else if (xRoot.rank > yRoot.rank) {
      yRoot.parent = xRoot;
      return xRoot;
    }
    yRoot.parent = xRoot;
    xRoot.rank = xRoot.rank + 1;
    return xRoot;
  }
}

final class Item<T> {
  Item<T>? parent;
  T value;
  int rank;

  Item(this.parent, this.value, [this.rank = 0]);

  @override
  int get hashCode => Object.hash(parent, value, rank);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is! Item<T>) {
      return false;
    }

    return other.parent == parent && other.value == value;
  }
}
