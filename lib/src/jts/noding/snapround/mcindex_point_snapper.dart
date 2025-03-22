import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/index/item_visitor.dart';
import 'package:dts/src/jts/index/monotone_chain.dart';
import 'package:dts/src/jts/index/spatial_index.dart';
import 'package:dts/src/jts/noding/noded_segment_string.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'hot_pixel.dart';

class MCIndexPointSnapper {
  final SpatialIndex<MonotoneChain> _index;

  MCIndexPointSnapper(this._index);

  bool snap2(HotPixel hotPixel, SegmentString? parentEdge, int hotPixelVertexIndex) {
    final Envelope pixelEnv = getSafeEnvelope(hotPixel);
    final hotPixelSnapAction = HotPixelSnapAction(hotPixel, parentEdge, hotPixelVertexIndex);
    _index.each(
      pixelEnv,
      ItemVisitor2((testChain) {
        testChain.select(pixelEnv, hotPixelSnapAction);
      }),
    );
    return hotPixelSnapAction.isNodeAdded();
  }

  bool snap(HotPixel hotPixel) {
    return snap2(hotPixel, null, -1);
  }

  static const double _SAFE_ENV_EXPANSION_FACTOR = 0.75;

  Envelope getSafeEnvelope(HotPixel hp) {
    double safeTolerance = _SAFE_ENV_EXPANSION_FACTOR / hp.getScaleFactor();
    Envelope safeEnv = Envelope.of(hp.getCoordinate());
    safeEnv.expandBy(safeTolerance);
    return safeEnv;
  }
}

class HotPixelSnapAction extends MonotoneChainSelectAction {
  final HotPixel _hotPixel;

  final SegmentString? _parentEdge;

  final int _hotPixelVertexIndex;

  bool _isNodeAdded = false;

  HotPixelSnapAction(this._hotPixel, this._parentEdge, this._hotPixelVertexIndex);

  bool isNodeAdded() {
    return _isNodeAdded;
  }

  @override
  void select2(MonotoneChain mc, int startIndex) {
    NodedSegmentString ss = mc.context as NodedSegmentString;
    if ((_parentEdge != null) && (ss == _parentEdge)) {
      if ((startIndex == _hotPixelVertexIndex) || ((startIndex + 1) == _hotPixelVertexIndex)) return;
    }
    _isNodeAdded |= addSnappedNode(_hotPixel, ss, startIndex);
  }

  bool addSnappedNode(HotPixel hotPixel, NodedSegmentString segStr, int segIndex) {
    Coordinate p0 = segStr.getCoordinate(segIndex);
    Coordinate p1 = segStr.getCoordinate(segIndex + 1);
    if (hotPixel.intersects2(p0, p1)) {
      segStr.addIntersection(hotPixel.getCoordinate(), segIndex);
      return true;
    }
    return false;
  }
}
