import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/index/spatial_index.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';

import 'polygon_topology_analyzer.dart';

final class IndexedNestedHoleTester {
  final Polygon polygon;
  late final SpatialIndex<LinearRing> index;

  Coordinate? _nestedPt;

  IndexedNestedHoleTester(this.polygon) {
    index = STRtree();
    for (int i = 0; i < polygon.getNumInteriorRing(); i++) {
      LinearRing hole = polygon.getInteriorRingN(i);
      Envelope env = hole.getEnvelopeInternal();
      index.insert(env, hole);
    }
  }

  Coordinate? getNestedPoint() {
    return _nestedPt;
  }

  bool isNested() {
    for (int i = 0; i < polygon.getNumInteriorRing(); i++) {
      LinearRing hole = polygon.getInteriorRingN(i);
      List<LinearRing> results = index.query(hole.getEnvelopeInternal());
      for (LinearRing testHole in results) {
        if (hole == testHole) continue;

        if (!testHole.getEnvelopeInternal().covers(hole.getEnvelopeInternal())) continue;

        if (PolygonTopologyAnalyzer.isRingNested(hole, testHole)) {
          _nestedPt = hole.getCoordinateN(0);
          return true;
        }
      }
    }
    return false;
  }
}
