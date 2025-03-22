import 'item_visitor.dart';

class ArrayListVisitor<T> implements ItemVisitor<T> {
  final List<T> _items = [];

  @override
  void visitItem(T item) {
    _items.add(item);
  }

  List<T> getItems() {
    return _items;
  }
}
