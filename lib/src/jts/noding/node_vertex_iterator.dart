import 'noded_segment_string.dart';
import 'segment_node.dart';
import 'segment_node_list.dart';

class NodeVertexIterator implements Iterator<SegmentNode> {
  final SegmentNodeList _nodeList;

  late NodedSegmentString edge;

  late Iterator<SegmentNode> _nodeIt;

  SegmentNode? _currNode;

  SegmentNode? _nextNode;

  int _currSegIndex = 0;

  NodeVertexIterator(this._nodeList) {
    edge = _nodeList.getEdge();
    _nodeIt = _nodeList.iterator().iterator;
    _readNextNode();
  }

  bool _hasNext() {
    if (_nextNode == null) return false;

    return true;
  }

  SegmentNode? _next() {
    if (_currNode == null) {
      _currNode = _nextNode;
      _currSegIndex = _currNode!.segmentIndex;
      _readNextNode();
      return _currNode!;
    }
    if (_nextNode == null) return null;

    if (_nextNode!.segmentIndex == _currNode!.segmentIndex) {
      _currNode = _nextNode;
      _currSegIndex = _currNode!.segmentIndex;
      _readNextNode();
      return _currNode;
    }
    if (_nextNode!.segmentIndex > _currNode!.segmentIndex) {}
    return null;
  }

  void _readNextNode() {
    if (_nodeIt.moveNext()) {
      _nextNode = _nodeIt.current;
    } else {
      _nextNode = null;
    }
  }

  @override
  SegmentNode get current {
    return _next()!;
  }

  @override
  bool moveNext() {
    return _hasNext();
  }
}
