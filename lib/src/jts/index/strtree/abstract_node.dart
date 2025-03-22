import 'package:dts/src/jts/util/assert.dart';

import 'boundable.dart';

abstract class AbstractNode<B> implements Boundable<B> {
  List<Boundable<B>> _childBoundables = [];
  B? _bounds;
  int level = 0;
  AbstractNode([this.level = 0]);

  List<Boundable<B>> getChildBoundables() {
    return _childBoundables;
  }

  B computeBounds();

  @override
  B getBounds() {
    _bounds ??= computeBounds();
    return _bounds!;
  }

  int size() {
    return _childBoundables.length;
  }

  bool isEmpty() {
    return _childBoundables.isEmpty;
  }

  void addChildBoundable(Boundable<B> childBoundable) {
    Assert.isTrue(_bounds == null);
    _childBoundables.add(childBoundable);
  }

  void setChildBoundables(List<Boundable<B>> childBoundables) {
    _childBoundables = childBoundables;
  }
}
