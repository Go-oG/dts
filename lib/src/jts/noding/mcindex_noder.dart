import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/index/hprtree.dart';
import 'package:dts/src/jts/index/monotone_chain.dart';
import 'package:dts/src/jts/index/spatial_index.dart';
import 'package:dts/src/jts/noding/segment_intersector.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'noded_segment_string.dart';
import 'single_pass_noder.dart';

class MCIndexNoder extends SinglePassNoder {
  final List<MonotoneChain> _monoChains = [];

  final SpatialIndex<MonotoneChain> _index = HPRtree();

  int _idCounter = 0;

  List<SegmentString> nodedSegStrings = [];

  int nOverlaps = 0;

  double _overlapTolerance = 0;

  MCIndexNoder();

  MCIndexNoder.of(super.si) : super.of();

  MCIndexNoder.of2(super.si, this._overlapTolerance) : super.of();

  List getMonotoneChains() {
    return _monoChains;
  }

  SpatialIndex<MonotoneChain> getIndex() {
    return _index;
  }

  @override
  List<SegmentString> getNodedSubstrings() {
    return NodedSegmentString.getNodedSubstrings(nodedSegStrings.cast());
  }

  @override
  void computeNodes(List<SegmentString> inputSegStrings) {
    nodedSegStrings = inputSegStrings;
    for (var i in inputSegStrings) {
      add(i);
    }
    intersectChains();
  }

  void intersectChains() {
    final overlapAction = SegmentOverlapAction(segInt!);
    for (var queryChain in _monoChains) {
      Envelope queryEnv = queryChain.getEnvelope(_overlapTolerance);
      List<MonotoneChain> overlapChains = _index.query(queryEnv);
      for (var testChain in overlapChains) {
        if (testChain.id > queryChain.id) {
          queryChain.computeOverlaps3(
              testChain, _overlapTolerance, overlapAction);
          nOverlaps++;
        }
        if (segInt!.isDone()) return;
      }
    }
  }

  void add(SegmentString segStr) {
    List<MonotoneChain> segChains =
        MonotoneChainBuilder.getChains(segStr.getCoordinates(), segStr);
    for (var mc in segChains) {
      mc.id = (_idCounter++);
      _index.insert(mc.getEnvelope(_overlapTolerance), mc);
      _monoChains.add(mc);
    }
  }
}

class SegmentOverlapAction extends MonotoneChainOverlapAction {
  final NSegmentIntersector _si;

  SegmentOverlapAction(this._si);

  @override
  void overlap2(MonotoneChain mc1, int start1, MonotoneChain mc2, int start2) {
    SegmentString ss1 = ((mc1.context as SegmentString));
    SegmentString ss2 = ((mc2.context as SegmentString));
    _si.processIntersections(ss1, start1, ss2, start2);
  }
}
