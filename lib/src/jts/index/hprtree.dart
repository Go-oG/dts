import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/index/array_list_visitor.dart';
import 'package:dts/src/jts/index/item_visitor.dart';
import 'package:dts/src/jts/index/spatial_index.dart';
import 'package:dts/src/jts/shape/fractal/hilbert_code.dart';

class HPRtree<T> implements SpatialIndex<T> {
  static const int _envSize = 4;
  static const int _hilbertLevel = 12;
  static const int _defaultNodeCapacity = 16;

  List<_Item> _itemsToLoad = [];

  final _totalExtent = Envelope();
  final int _nodeCapacity;
  late Array<double> _nodeBounds;
  late Array<double> _itemBounds;
  late Array<T> _itemValues;

  int _numItems = 0;
  Array<int>? _layerStartIndex;
  bool _isBuilt = false;

  HPRtree([this._nodeCapacity = _defaultNodeCapacity]);

  int size() {
    return _numItems;
  }

  @override
  void insert(Envelope itemEnv, T item) {
    if (_isBuilt) {
      throw ("Cannot insert items after tree is built.");
    }
    _numItems++;
    _itemsToLoad.add(_Item(itemEnv, item));
    _totalExtent.expandToInclude(itemEnv);
  }

  @override
  List<T> query(Envelope searchEnv) {
    build();
    if (!_totalExtent.intersects(searchEnv)) {
      return [];
    }

    ArrayListVisitor<T> visitor = ArrayListVisitor();
    each(searchEnv, visitor);
    return visitor.getItems();
  }

  @override
  void each(Envelope searchEnv, ItemVisitor<T> visitor) {
    build();
    if (!_totalExtent.intersects(searchEnv)) {
      return;
    }

    if (_layerStartIndex == null) {
      queryItems(0, searchEnv, visitor);
    } else {
      queryTopLayer(searchEnv, visitor);
    }
  }

  void queryTopLayer(Envelope searchEnv, ItemVisitor<T> visitor) {
    int layerIndex = _layerStartIndex!.length - 2;
    int layerSizeV = layerSize(layerIndex);
    for (int i = 0; i < layerSizeV; i += _envSize) {
      queryNode(layerIndex, i, searchEnv, visitor);
    }
  }

  void queryNode(int layerIndex, int nodeOffset, Envelope searchEnv,
      ItemVisitor<T> visitor) {
    int layerStart = _layerStartIndex![layerIndex];
    int nodeIndex = layerStart + nodeOffset;
    if (!intersects(_nodeBounds, nodeIndex, searchEnv)) {
      return;
    }

    if (layerIndex == 0) {
      int childNodesOffset = (nodeOffset ~/ _envSize) * _nodeCapacity;
      queryItems(childNodesOffset, searchEnv, visitor);
    } else {
      int childNodesOffset = nodeOffset * _nodeCapacity;
      queryNodeChildren(layerIndex - 1, childNodesOffset, searchEnv, visitor);
    }
  }

  static bool intersects(Array<double> bounds, int nodeIndex, Envelope env) {
    bool isBeyond = (((env.maxX < bounds[nodeIndex]) ||
                (env.maxY < bounds[nodeIndex + 1])) ||
            (env.minX > bounds[nodeIndex + 2])) ||
        (env.minY > bounds[nodeIndex + 3]);
    return !isBeyond;
  }

  void queryNodeChildren(int layerIndex, int blockOffset, Envelope searchEnv,
      ItemVisitor<T> visitor) {
    int layerStart = _layerStartIndex![layerIndex];
    int layerEnd = _layerStartIndex![layerIndex + 1];
    for (int i = 0; i < _nodeCapacity; i++) {
      int nodeOffset = blockOffset + (_envSize * i);
      if ((layerStart + nodeOffset) >= layerEnd) {
        break;
      }

      queryNode(layerIndex, nodeOffset, searchEnv, visitor);
    }
  }

  void queryItems(int blockStart, Envelope searchEnv, ItemVisitor<T> visitor) {
    for (int i = 0; i < _nodeCapacity; i++) {
      int itemIndex = blockStart + i;
      if (itemIndex >= _numItems) {
        break;
      }
      if (intersects(_itemBounds, itemIndex * _envSize, searchEnv)) {
        visitor.visitItem(_itemValues[itemIndex]);
      }
    }
  }

  int layerSize(int layerIndex) {
    int layerStart = _layerStartIndex![layerIndex];
    int layerEnd = _layerStartIndex![layerIndex + 1];
    return layerEnd - layerStart;
  }

  @override
  bool remove(Envelope itemEnv, T item) {
    return false;
  }

  void build() {
    if (!_isBuilt) {
      prepareIndex();
      prepareItems();
      _isBuilt = true;
    }
  }

  void prepareIndex() {
    if (_itemsToLoad.size <= _nodeCapacity) {
      return;
    }
    sortItems();
    _layerStartIndex = computeLayerIndices(_numItems, _nodeCapacity);
    int nodeCount = _layerStartIndex![_layerStartIndex!.length - 1] ~/ 4;
    _nodeBounds = createBoundsArray(nodeCount);
    computeLeafNodes(_layerStartIndex![1]);
    for (int i = 1; i < (_layerStartIndex!.length - 1); i++) {
      computeLayerNodes(i);
    }
  }

  void prepareItems() {
    int boundsIndex = 0;
    int valueIndex = 0;
    _itemBounds = Array(_itemsToLoad.size * 4);
    _itemValues = Array(_itemsToLoad.size);

    for (_Item item in _itemsToLoad) {
      Envelope envelope = item.getEnvelope();
      _itemBounds[boundsIndex++] = envelope.minX;
      _itemBounds[boundsIndex++] = envelope.minY;
      _itemBounds[boundsIndex++] = envelope.maxX;
      _itemBounds[boundsIndex++] = envelope.maxY;
      _itemValues[valueIndex++] = item.getItem();
    }
    _itemsToLoad = [];
  }

  static Array<double> createBoundsArray(int size) {
    Array<double> a = Array(4 * size);
    for (int i = 0; i < size; i++) {
      int index = 4 * i;
      a[index] = double.maxFinite;
      a[index + 1] = double.maxFinite;
      a[index + 2] = -double.maxFinite;
      a[index + 3] = -double.maxFinite;
    }
    return a;
  }

  void computeLayerNodes(int layerIndex) {
    int layerStart = _layerStartIndex![layerIndex];
    int childLayerStart = _layerStartIndex![layerIndex - 1];
    int layerSizeV = layerSize(layerIndex);
    int childLayerEnd = layerStart;
    for (int i = 0; i < layerSizeV; i += _envSize) {
      int childStart = childLayerStart + (_nodeCapacity * i);
      computeNodeBounds(layerStart + i, childStart, childLayerEnd);
    }
  }

  void computeNodeBounds(int nodeIndex, int blockStart, int nodeMaxIndex) {
    final nodeBounds = _nodeBounds;
    for (int i = 0; i <= _nodeCapacity; i++) {
      int index = blockStart + (4 * i);
      if (index >= nodeMaxIndex) {
        break;
      }

      updateNodeBounds(
        nodeIndex,
        nodeBounds[index],
        nodeBounds[index + 1],
        nodeBounds[index + 2],
        nodeBounds[index + 3],
      );
    }
  }

  void computeLeafNodes(int layerSize) {
    for (int i = 0; i < layerSize; i += _envSize) {
      computeLeafNodeBounds(i, (_nodeCapacity * i) ~/ 4);
    }
  }

  void computeLeafNodeBounds(int nodeIndex, int blockStart) {
    for (int i = 0; i <= _nodeCapacity; i++) {
      int itemIndex = blockStart + i;
      if (itemIndex >= _itemsToLoad.size) {
        break;
      }

      Envelope env = _itemsToLoad.get(itemIndex).getEnvelope();
      updateNodeBounds(nodeIndex, env.minX, env.minY, env.maxX, env.maxY);
    }
  }

  void updateNodeBounds(
      int nodeIndex, double minX, double minY, double maxX, double maxY) {
    final nodeBounds = _nodeBounds;
    if (minX < nodeBounds[nodeIndex]) {
      nodeBounds[nodeIndex] = minX;
    }

    if (minY < nodeBounds[nodeIndex + 1]) {
      nodeBounds[nodeIndex + 1] = minY;
    }

    if (maxX > nodeBounds[nodeIndex + 2]) {
      nodeBounds[nodeIndex + 2] = maxX;
    }

    if (maxY > nodeBounds[nodeIndex + 3]) {
      nodeBounds[nodeIndex + 3] = maxY;
    }
  }

  static Array<int> computeLayerIndices(int itemSize, int nodeCapacity) {
    List<int> layerIndexList = [];
    int layerSize = itemSize;
    int index = 0;
    do {
      layerIndexList.add(index);
      layerSize = numNodesToCover(layerSize, nodeCapacity);
      index += _envSize * layerSize;
    } while (layerSize > 1);
    return layerIndexList.toArray();
  }

  static int numNodesToCover(int nChild, int nodeCapacity) {
    int mult = nChild ~/ nodeCapacity;
    int total = mult * nodeCapacity;
    if (total == nChild) {
      return mult;
    }

    return mult + 1;
  }

  Array<Envelope> getBounds() {
    final nodeBounds = _nodeBounds;
    int numNodes = nodeBounds.size ~/ 4;
    Array<Envelope> bounds = Array(numNodes);
    for (int i = numNodes - 1; i >= 0; i--) {
      int boundIndex = 4 * i;
      bounds[i] = Envelope.fromLTRB(
        nodeBounds[boundIndex],
        nodeBounds[boundIndex + 1],
        nodeBounds[boundIndex + 2],
        nodeBounds[boundIndex + 3],
      );
    }
    return bounds;
  }

  void sortItems() {
    final encoder = _Encoder(_hilbertLevel, _totalExtent);
    Array<int> hilbertValues = Array(_itemsToLoad.size);
    int pos = 0;
    for (_Item item in _itemsToLoad) {
      hilbertValues[pos++] = encoder.encode(item.getEnvelope());
    }
    quickSortItemsIntoNodes(hilbertValues, 0, _itemsToLoad.size - 1);
  }

  void quickSortItemsIntoNodes(Array<int> values, int lo, int hi) {
    if ((lo / _nodeCapacity) < (hi / _nodeCapacity)) {
      int pivot = hoarePartition(values, lo, hi);
      quickSortItemsIntoNodes(values, lo, pivot);
      quickSortItemsIntoNodes(values, pivot + 1, hi);
    }
  }

  int hoarePartition(Array<int> values, int lo, int hi) {
    int pivot = values[(lo + hi) >> 1];
    int i = lo - 1;
    int j = hi + 1;
    while (true) {
      do {
        i++;
      } while (values[i] < pivot);
      do {
        j--;
      } while (values[j] > pivot);
      if (i >= j) {
        return j;
      }

      swapItems(values, i, j);
    }
  }

  void swapItems(Array<int> values, int i, int j) {
    _Item tmpItemp = _itemsToLoad.get(i);
    _itemsToLoad.set(i, _itemsToLoad.get(j));
    _itemsToLoad.set(j, tmpItemp);
    int tmpValue = values[i];
    values[i] = values[j];
    values[j] = tmpValue;
  }
}

class _Encoder {
  int level;

  double minx = 0;

  double miny = 0;

  double _strideX = 0;

  double _strideY = 0;

  _Encoder(this.level, Envelope extent) {
    int hside = ((Math.pow(2, level)).toInt()) - 1;
    minx = extent.minX;
    _strideX = extent.width / hside;
    miny = extent.minY;
    _strideY = extent.height / hside;
  }

  int encode(Envelope env) {
    double midx = (env.width / 2) + env.minX;
    int x = (((midx - minx) ~/ _strideX));
    double midy = (env.height / 2) + env.minY;
    int y = (((midy - miny) ~/ _strideY));
    return HilbertCode.encode(level, x, y);
  }
}

class _Item<T> {
  Envelope env;
  final T _item;

  _Item(this.env, this._item);

  Envelope getEnvelope() {
    return env;
  }

  T getItem() {
    return _item;
  }

  @override
  String toString() {
    return "Item: $env";
  }
}
