import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/index/item_visitor.dart';
import 'package:dts/src/jts/index/monotone_chain.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';

class SegmentMCIndex {
  late STRtree<MonotoneChain> index;

  SegmentMCIndex(List<Coordinate> segs) {
    index = buildIndex(segs);
  }

  STRtree<MonotoneChain> buildIndex(List<Coordinate> segs) {
    STRtree<MonotoneChain> index = STRtree();
    List<MonotoneChain> segChains = MonotoneChainBuilder.getChains(segs, segs);
    for (MonotoneChain mc in segChains) {
      index.insert(mc.getEnvelope(), mc);
    }
    return index;
  }

  void query(Envelope env, MonotoneChainSelectAction action) {
    index.each(
      env,
      ItemVisitor2<MonotoneChain>((item) {
        item.select(env, action);
      }),
    );
  }
}
