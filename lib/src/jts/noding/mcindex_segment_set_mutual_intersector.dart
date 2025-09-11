import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/index/monotone_chain.dart';
import 'package:dts/src/jts/index/spatial_index.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';

import 'segment_intersector.dart';
import 'segment_set_mutual_intersector.dart';
import 'segment_string.dart';

class MCIndexSegmentSetMutualIntersector
    implements SegmentSetMutualIntersector {
  final STRtree _index = STRtree();
  final Envelope? _envelope;

  double _overlapTolerance = 0.0;

  MCIndexSegmentSetMutualIntersector(List<SegmentString> baseSegStrings,
      [this._envelope, double overlapTolerance = 0]) {
    initBaseSegments(baseSegStrings);
    _overlapTolerance = overlapTolerance;
  }

  SpatialIndex getIndex() {
    return _index;
  }

  void initBaseSegments(List<SegmentString> segStrings) {
    for (var ss in segStrings) {
      if (ss.size() == 0) {
        continue;
      }
      addToIndex(ss);
    }
    _index.build();
  }

  void addToIndex(SegmentString segStr) {
    List<MonotoneChain> segChains =
        MonotoneChainBuilder.getChains(segStr.getCoordinates(), segStr);
    for (var mc in segChains) {
      if ((_envelope == null) || _envelope!.intersects(mc.getEnvelope())) {
        _index.insert(mc.getEnvelope(_overlapTolerance), mc);
      }
    }
  }

  @override
  void process(List<SegmentString> segStrings, NSegmentIntersector segInt) {
    List<MonotoneChain> monoChains = [];
    for (var i in segStrings) {
      addToMonoChains(i, monoChains);
    }
    intersectChains(monoChains, segInt);
  }

  void addToMonoChains(SegmentString segStr, List monoChains) {
    if (segStr.size() == 0) {
      return;
    }

    final segChains =
        MonotoneChainBuilder.getChains(segStr.getCoordinates(), segStr);
    for (var mc in segChains) {
      if ((_envelope == null) || _envelope!.intersects(mc.getEnvelope())) {
        monoChains.add(mc);
      }
    }
  }

  void intersectChains(
      List<MonotoneChain> monoChains, NSegmentIntersector segInt) {
    final overlapAction = _SegmentOverlapAction(segInt);
    for (var queryChain in monoChains) {
      Envelope queryEnv = queryChain.getEnvelope(_overlapTolerance);
      final overlapChains = _index.query(queryEnv);
      for (var testChain in overlapChains) {
        queryChain.computeOverlaps3(
            testChain, _overlapTolerance, overlapAction);
        if (segInt.isDone()) {
          return;
        }
      }
    }
  }
}

class _SegmentOverlapAction extends MonotoneChainOverlapAction {
  final NSegmentIntersector si;

  _SegmentOverlapAction(this.si);

  @override
  void overlap2(MonotoneChain mc1, int start1, MonotoneChain mc2, int start2) {
    SegmentString ss1 = mc1.getContext() as SegmentString;
    SegmentString ss2 = mc2.getContext() as SegmentString;
    si.processIntersections(ss1, start1, ss2, start2);
  }
}
