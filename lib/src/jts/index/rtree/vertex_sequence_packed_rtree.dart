 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/math/math.dart';

import '../../geom/coordinate.dart';
import '../../geom/envelope.dart';

class VertexSequencePackedRtree {
  final Array<Coordinate> _items;
  final int _nodeCapacity = 16;
  late Array<int> _levelOffset;
  late Array<Envelope?> _bounds;
  late Array<bool> _isRemoved;

  VertexSequencePackedRtree(this._items) {
    _isRemoved = Array(_items.length);
    build();
  }

  Array<Envelope?> getBounds() {
    return _bounds.copy();
  }

  void build() {
    _levelOffset = computeLevelOffsets();
    _bounds = createBounds();
  }

  Array<int> computeLevelOffsets() {
    List<int> offsets = [];
    offsets.add(0);
    int levelSize = _items.length;
    int currOffset = 0;
    do {
      levelSize = levelNodeCount(levelSize);
      currOffset += levelSize;
      offsets.add(currOffset);
    } while (levelSize > 1);
    return offsets.toArray();
  }

  int levelNodeCount(int numNodes) {
    return MathUtil.ceil(numNodes, _nodeCapacity);
  }

  Array<Envelope> createBounds() {
    int boundsSize = _levelOffset[_levelOffset.length - 1] + 1;
    Array<Envelope> bounds = Array(boundsSize);
    fillItemBounds(bounds);
    for (int lvl = 1; lvl < _levelOffset.length; lvl++) {
      fillLevelBounds(lvl, bounds);
    }
    return bounds;
  }

  void fillLevelBounds(int lvl, Array<Envelope> bounds) {
    int levelStart = _levelOffset[lvl - 1];
    int levelEnd = _levelOffset[lvl];
    int nodeStart = levelStart;
    int levelBoundIndex = _levelOffset[lvl];
    do {
      int nodeEnd = MathUtil.clampMax(nodeStart + _nodeCapacity, levelEnd);
      bounds[levelBoundIndex++] = computeNodeEnvelope(bounds, nodeStart, nodeEnd);
      nodeStart = nodeEnd;
    } while (nodeStart < levelEnd);
  }

  void fillItemBounds(Array<Envelope> bounds) {
    int nodeStart = 0;
    int boundIndex = 0;
    do {
      int nodeEnd = MathUtil.clampMax(nodeStart + _nodeCapacity, _items.length);
      bounds[boundIndex++] = computeItemEnvelope(_items, nodeStart, nodeEnd);
      nodeStart = nodeEnd;
    } while (nodeStart < _items.length);
  }

  static Envelope computeNodeEnvelope(Array<Envelope> bounds, int start, int end) {
    Envelope env = Envelope();
    for (int i = start; i < end; i++) {
      env.expandToInclude3(bounds[i]);
    }
    return env;
  }

  static Envelope computeItemEnvelope(Array<Coordinate> items, int start, int end) {
    Envelope env = Envelope();
    for (int i = start; i < end; i++) {
      env.expandToInclude(items[i]);
    }
    return env;
  }

  Array<int> query(Envelope queryEnv) {
    List<int> resultList = [];
    int level = _levelOffset.length - 1;
    queryNode(queryEnv, level, 0, resultList);
    Array<int> result = resultList.toArray();
    return result;
  }

  void queryNode(Envelope queryEnv, int level, int nodeIndex, List<int> resultList) {
    int boundsIndex = _levelOffset[level] + nodeIndex;
    Envelope? nodeEnv = _bounds[boundsIndex];
    if (nodeEnv == null) return;

    if (!queryEnv.intersects6(nodeEnv)) {
      return;
    }

    int childNodeIndex = nodeIndex * _nodeCapacity;
    if (level == 0) {
      queryItemRange(queryEnv, childNodeIndex, resultList);
    } else {
      queryNodeRange(queryEnv, level - 1, childNodeIndex, resultList);
    }
  }

  void queryNodeRange(Envelope queryEnv, int level, int nodeStartIndex, List<int> resultList) {
    int levelMax = levelSize(level);
    for (int i = 0; i < _nodeCapacity; i++) {
      int index = nodeStartIndex + i;
      if (index >= levelMax) {
        return;
      }

      queryNode(queryEnv, level, index, resultList);
    }
  }

  int levelSize(int level) {
    return _levelOffset[level + 1] - _levelOffset[level];
  }

  void queryItemRange(Envelope queryEnv, int itemIndex, List<int> resultList) {
    for (int i = 0; i < _nodeCapacity; i++) {
      int index = itemIndex + i;
      if (index >= _items.length) {
        return;
      }

      Coordinate p = _items[index];
      if ((!_isRemoved[index]) && queryEnv.contains(p)) resultList.add(index);
    }
  }

  void remove(int index) {
    _isRemoved[index] = true;
    int nodeIndex = index ~/ _nodeCapacity;
    if (!isItemsNodeEmpty(nodeIndex)) return;

    _bounds[nodeIndex] = null;
    if (_levelOffset.length <= 2) {
      return;
    }

    int nodeLevelIndex = nodeIndex ~/ _nodeCapacity;
    if (!isNodeEmpty(1, nodeLevelIndex)) return;

    int nodeIndex1 = _levelOffset[1] + nodeLevelIndex;
    _bounds[nodeIndex1] = null;
  }

  bool isNodeEmpty(int level, int index) {
    int start = index * _nodeCapacity;
    int end = MathUtil.clampMax(start + _nodeCapacity, _levelOffset[level]);
    for (int i = start; i < end; i++) {
      if (_bounds[i] != null) {
        return false;
      }
    }
    return true;
  }

  bool isItemsNodeEmpty(int nodeIndex) {
    int start = nodeIndex * _nodeCapacity;
    int end = MathUtil.clampMax(start + _nodeCapacity, _items.length);
    for (int i = start; i < end; i++) {
      if (!_isRemoved[i]) {
        return false;
      }
    }
    return true;
  }
}
