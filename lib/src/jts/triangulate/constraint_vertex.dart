import 'package:dts/src/jts/triangulate/quadedge/vertex.dart';

class ConstraintVertex extends Vertex {
  bool _isOnConstraint = false;

  Object? _constraint;

  ConstraintVertex(super.p) : super.of();

  void setOnConstraint(bool isOnConstraint) {
    _isOnConstraint = isOnConstraint;
  }

  bool isOnConstraint() {
    return _isOnConstraint;
  }

  void setConstraint(Object constraint) {
    _isOnConstraint = true;
    _constraint = constraint;
  }

  Object? getConstraint() {
    return _constraint;
  }

  void merge(ConstraintVertex other) {
    if (other._isOnConstraint) {
      _isOnConstraint = true;
      _constraint = other._constraint;
    }
  }
}
