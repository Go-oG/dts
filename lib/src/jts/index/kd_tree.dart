import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/envelope.dart';

class KdTree {
  static Array<Coordinate> toCoordinates(List<KdNode> nodes, [bool includeRepeated = false]) {
    CoordinateList coord = CoordinateList();
    for (var node in nodes) {
      int count = (includeRepeated) ? node.getCount() : 1;
      for (int i = 0; i < count; i++) {
        coord.add3(node.getCoordinate(), true);
      }
    }
    return coord.toCoordinateArray();
  }

  KdNode? _root;

  int _numberOfNodes = 0;

  double tolerance;

  KdTree([this.tolerance = 0]);

  KdNode? getRoot() {
    return _root;
  }

  bool isEmpty() {
    if (_root == null) {
      return true;
    }
    return false;
  }

  KdNode insert(Coordinate p) {
    return insert2(p, null);
  }

  KdNode insert2(Coordinate p, Object? data) {
    if (_root == null) {
      _root = KdNode.of(p, data);
      return _root!;
    }
    if (tolerance > 0) {
      KdNode? matchNode = findBestMatchNode(p);
      if (matchNode != null) {
        matchNode.increment();
        return matchNode;
      }
    }
    return insertExact(p, data);
  }

  KdNode? findBestMatchNode(Coordinate p) {
    final visitor = BestMatchVisitor(p, tolerance);
    query3(visitor.queryEnvelope(), visitor);
    return visitor.getNode();
  }

  KdNode insertExact(Coordinate p, Object? data) {
    KdNode? currentNode = _root;
    KdNode? leafNode = _root;
    bool isXLevel = true;
    bool isLessThan = true;
    while (currentNode != null) {
      bool isInTolerance = p.distance(currentNode.getCoordinate()) <= tolerance;
      if (isInTolerance) {
        currentNode.increment();
        return currentNode;
      }
      double splitValue = currentNode.splitValue(isXLevel);
      if (isXLevel) {
        isLessThan = p.x < splitValue;
      } else {
        isLessThan = p.y < splitValue;
      }
      leafNode = currentNode;
      if (isLessThan) {
        currentNode = currentNode.getLeft();
      } else {
        currentNode = currentNode.getRight();
      }
      isXLevel = !isXLevel;
    }
    _numberOfNodes = _numberOfNodes + 1;
    KdNode node = KdNode.of(p, data);
    if (isLessThan) {
      leafNode!.setLeft(node);
    } else {
      leafNode!.setRight(node);
    }
    return node;
  }

  void query3(Envelope queryEnv, KdNodeVisitor visitor) {
    List<_QueryStackFrame> queryStack = [];
    KdNode? currentNode = _root;
    bool isXLevel = true;
    while (true) {
      if (currentNode != null) {
        queryStack.add(_QueryStackFrame(currentNode, isXLevel));
        bool searchLeft = currentNode.isRangeOverLeft(isXLevel, queryEnv);
        if (searchLeft) {
          currentNode = currentNode.getLeft();
          if (currentNode != null) {
            isXLevel = !isXLevel;
          }
        } else {
          currentNode = null;
        }
      } else if (queryStack.isNotEmpty) {
        _QueryStackFrame frame = queryStack.removeAt(0);
        currentNode = frame.node;
        isXLevel = frame.isXLevel;
        if (queryEnv.containsCoordinate(currentNode.getCoordinate())) {
          visitor.visit(currentNode);
        }
        bool searchRight = currentNode.isRangeOverRight(isXLevel, queryEnv);
        if (searchRight) {
          currentNode = currentNode.getRight();
          if (currentNode != null) {
            isXLevel = !isXLevel;
          }
        } else {
          currentNode = null;
        }
      } else {
        return;
      }
    }
  }

  List query2(Envelope queryEnv) {
    final List result = [];
    query4(queryEnv, result);
    return result;
  }

  void query4(Envelope queryEnv, final List result) {
    query3(
      queryEnv,
      KdNodeVisitor2((node) {
        result.add(node);
      }),
    );
  }

  KdNode? query(Coordinate queryPt) {
    KdNode? currentNode = _root;
    bool isXLevel = true;
    while (currentNode != null) {
      if (currentNode.getCoordinate().equals2D(queryPt)) {
        return currentNode;
      }

      bool searchLeft = currentNode.isPointOnLeft(isXLevel, queryPt);
      if (searchLeft) {
        currentNode = currentNode.getLeft();
      } else {
        currentNode = currentNode.getRight();
      }
      isXLevel = !isXLevel;
    }
    return null;
  }

  int depth() {
    return depthNode(_root);
  }

  int depthNode(KdNode? currentNode) {
    if (currentNode == null) {
      return 0;
    }

    int dL = depthNode(currentNode.getLeft());
    int dR = depthNode(currentNode.getRight());
    return 1 + (dL > dR ? dL : dR);
  }

  int size() {
    return sizeNode(_root);
  }

  int sizeNode(KdNode? currentNode) {
    if (currentNode == null) {
      return 0;
    }

    int sizeL = sizeNode(currentNode.getLeft());
    int sizeR = sizeNode(currentNode.getRight());
    return (1 + sizeL) + sizeR;
  }
}

class BestMatchVisitor implements KdNodeVisitor {
  double tolerance;

  KdNode? _matchNode;

  double _matchDist = 0.0;

  Coordinate p;

  BestMatchVisitor(this.p, this.tolerance);

  Envelope queryEnvelope() {
    Envelope queryEnv = Envelope.fromCoordinate(p);
    queryEnv.expandBy(tolerance);
    return queryEnv;
  }

  KdNode? getNode() {
    return _matchNode;
  }

  @override
  void visit(KdNode node) {
    double dist = p.distance(node.getCoordinate());
    bool isInTolerance = dist <= tolerance;
    if (!isInTolerance) {
      return;
    }

    bool update = false;
    if (((_matchNode == null) || (dist < _matchDist)) ||
        (((_matchNode != null) && (dist == _matchDist)) &&
            (node.getCoordinate().compareTo(_matchNode!.getCoordinate()) < 1))) {
      update = true;
    }

    if (update) {
      _matchNode = node;
      _matchDist = dist;
    }
  }
}

class KdNode {
  late Coordinate _p;

  final Object? _data;

  KdNode? _left;

  KdNode? _right;

  int _count = 0;

  KdNode(double x, double y, this._data) {
    _p = Coordinate(x, y);
    _count = 1;
  }

  KdNode.of(Coordinate p, this._data) {
    _p = Coordinate.of(p);
    _count = 1;
  }

  double getX() {
    return _p.x;
  }

  double getY() {
    return _p.y;
  }

  double splitValue(bool isSplitOnX) {
    if (isSplitOnX) {
      return _p.x;
    }
    return _p.y;
  }

  Coordinate getCoordinate() {
    return _p;
  }

  Object? getData() {
    return _data;
  }

  KdNode? getLeft() {
    return _left;
  }

  KdNode? getRight() {
    return _right;
  }

  void increment() {
    _count = _count + 1;
  }

  int getCount() {
    return _count;
  }

  bool isRepeated() {
    return _count > 1;
  }

  void setLeft(KdNode left) {
    _left = left;
  }

  void setRight(KdNode right) {
    _right = right;
  }

  bool isRangeOverLeft(bool isSplitOnX, Envelope env) {
    double envMin;
    if (isSplitOnX) {
      envMin = env.minX;
    } else {
      envMin = env.minY;
    }
    bool isInRange = envMin < splitValue(isSplitOnX);
    return isInRange;
  }

  bool isRangeOverRight(bool isSplitOnX, Envelope env) {
    double envMax;
    if (isSplitOnX) {
      envMax = env.maxX;
    } else {
      envMax = env.maxY;
    }

    return splitValue(isSplitOnX) <= envMax;
  }

  bool isPointOnLeft(bool isSplitOnX, Coordinate pt) {
    double ptOrdinate;
    if (isSplitOnX) {
      ptOrdinate = pt.x;
    } else {
      ptOrdinate = pt.y;
    }

    return ptOrdinate < splitValue(isSplitOnX);
  }
}

abstract interface class KdNodeVisitor {
  void visit(KdNode node);
}

class KdNodeVisitor2 implements KdNodeVisitor {
  final void Function(KdNode node) visitFun;

  KdNodeVisitor2(this.visitFun);

  @override
  void visit(KdNode node) {
    visitFun.call(node);
  }
}

class _QueryStackFrame {
  final KdNode node;

  final bool isXLevel;

  const _QueryStackFrame(this.node, this.isXLevel);
}
