import 'package:dts/src/jts/geom/envelope.dart';

import 'ring_hull.dart';

class RingHullIndex {
  List<RingHull> hulls = [];

  void add(RingHull ringHull) {
        hulls.add(ringHull);
  }

  List<RingHull> query(Envelope queryEnv) {
    List<RingHull> result = [];
    for (RingHull hull in hulls) {
      Envelope envHull = hull.getEnvelope();
      if (queryEnv.intersects6(envHull)) {
        result.add(hull);
            }
        }
        return result;
    }
}
