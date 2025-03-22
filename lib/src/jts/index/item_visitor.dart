abstract interface class ItemVisitor<T> {
  void visitItem(T item);
}

class ItemVisitor2<T> implements ItemVisitor<T> {
  final void Function(T item) visitFun;

  ItemVisitor2(this.visitFun);

  @override
  void visitItem(T item) {
    visitFun(item);
  }
}
