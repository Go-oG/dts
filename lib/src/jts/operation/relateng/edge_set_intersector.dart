import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/index/hprtree.dart';
import 'package:dts/src/jts/index/monotone_chain.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'edge_segment_intersector.dart';
import 'edge_segment_overlap_action.dart';
import 'relate_segment_string.dart';

class OpEdgeSetIntersector {
  final _index = HPRtree<MonotoneChain>();

  Envelope? envelope;

  final List<MonotoneChain> _monoChains = [];

  int idCounter = 0;

  OpEdgeSetIntersector(
      List<RelateSegmentString> edgesA, List<RelateSegmentString> edgesB, this.envelope) {
    addEdges(edgesA);
    addEdges(edgesB);
    _index.build();
  }

  void addEdges(List<RelateSegmentString> segStrings) {
    for (SegmentString ss in segStrings) {
      addToIndex(ss);
    }
  }

  void addToIndex(SegmentString segStr) {
    final segChains = MonotoneChainBuilder.getChains(segStr.getCoordinates(), segStr);
    for (MonotoneChain mc in segChains) {
      if ((envelope == null) || envelope!.intersects(mc.getEnvelope())) {
        mc.id = (idCounter++);
        _index.insert(mc.getEnvelope(), mc);
        _monoChains.add(mc);
      }
    }
  }

  void process(EdgeSegmentIntersector intersector) {
    final overlapAction = EdgeSegmentOverlapAction(intersector);
    for (MonotoneChain queryChain in _monoChains) {
      List<MonotoneChain> overlapChains = _index.query(queryChain.getEnvelope());
      for (MonotoneChain testChain in overlapChains) {
        if (testChain.id <= queryChain.id) {
          continue;
        }

        testChain.computeOverlaps(queryChain, overlapAction);
        if (intersector.isDone()) {
          return;
        }
      }
    }
  }
}
