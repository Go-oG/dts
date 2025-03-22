import 'package:dts/dts.dart';

abstract interface class ItemDistance<T, B> {
  double distance(ItemBoundable<T, B> item1, ItemBoundable<T, B> item2);
}

class GeometryItemDistance<B> implements ItemDistance<Geometry, B> {
  @override
  double distance(final item1, final item2) {
    if (item1 == item2) {
      return double.maxFinite;
    }
    return item1.item.distance(item2.item);
  }
}
