import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/index/strtree/boundable.dart';

import '../../util/assert.dart';
import 'abstract_node.dart';
import 'abstract_strtree.dart';

class SIRtree<T> extends AbstractSTRtree<T, Interval> {
  final _comparator = CComparator2<Boundable<Interval>>((o1, o2) {
    var v1 = o1.getBounds().getCentre();
    var v2 = o2.getBounds().getCentre();
    return AbstractSTRtree.compareDoubles(v1, v2);
  });

  final _intersectsOp = IntersectsOp2<Interval>((a, b) {
    return (a).intersects(b);
  });

  SIRtree([super.nodeCapacity = 10]);

  @override
  AbstractNode<Interval> createNode(int level) {
    return _SIRNode(level);
  }

  void insert2(double x1, double x2, T item) {
    super.insert(Interval(Math.minD(x1, x2), Math.maxD(x1, x2)), item);
  }

  List<T> query3(double x) {
    return query4(x, x);
  }

  List<T> query4(double x1, double x2) {
    return super.query(Interval(Math.minD(x1, x2), Math.maxD(x1, x2)));
  }

  @override
  IntersectsOp<Interval> getIntersectsOp() {
    return _intersectsOp;
  }

  @override
  CComparator<Boundable<Interval>> getComparator() {
    return _comparator;
  }
}

class _SIRNode extends AbstractNode<Interval> {
  _SIRNode(super.level);

  @override
  Interval computeBounds() {
    Interval? bounds;
    for (var childBoundable in getChildBoundables()) {
      if (bounds == null) {
        bounds = Interval.of(childBoundable.getBounds());
      } else {
        bounds.expandToInclude(childBoundable.getBounds());
      }
    }
    return bounds!;
  }
}

class Interval {
  double _min = 0;

  double _max = 0;

  Interval.of(Interval other) : this(other._min, other._max);

  Interval(double min, double max) {
    Assert.isTrue(min <= max);
    _min = min;
    _max = max;
  }

  double getCentre() {
    return (_min + _max) / 2;
  }

  Interval expandToInclude(Interval other) {
    _max = Math.maxD(_max, other._max);
    _min = Math.minD(_min, other._min);
    return this;
  }

  bool intersects(Interval other) {
    return !((other._min > _max) || (other._max < _min));
  }

  @override
  int get hashCode {
    final int prime = 31;
    int result = 1;
    int temp;
    temp = Double.doubleToLongBits(_max);
    result = (prime * result) + ((temp ^ (temp >>> 32)));
    temp = Double.doubleToLongBits(_min);
    result = (prime * result) + ((temp ^ (temp >>> 32)));
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Interval) {
      return false;
    }
    return (_min == other._min) && (_max == other._max);
  }
}
