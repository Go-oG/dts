import 'package:dts/src/jts/geom/envelope.dart';

import 'item_visitor.dart';

abstract interface class SpatialIndex<T> {
  void insert(Envelope itemEnv, T item);

  List<T> query(Envelope searchEnv);

  void each(Envelope searchEnv, ItemVisitor<T> visitor);

  bool remove(Envelope itemEnv, T item);
}
