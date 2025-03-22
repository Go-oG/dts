 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/index/strtree/item_distance.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';

import 'facet_sequence.dart';
import 'facet_sequence_tree_builder.dart';
import 'geometry_location.dart';

class IndexedFacetDistance {
  static final _FACET_SEQ_DIST = FacetSequenceDistance();

  static double distance2(Geometry g1, Geometry g2) {
    IndexedFacetDistance dist = IndexedFacetDistance(g1);
    return dist.distance(g2);
  }

  static bool isWithinDistance2(Geometry g1, Geometry g2, double distance) {
    IndexedFacetDistance dist = IndexedFacetDistance(g1);
    return dist.isWithinDistance(g2, distance);
  }

  static Array<Coordinate>? nearestPoints2(Geometry g1, Geometry g2) {
    IndexedFacetDistance dist = IndexedFacetDistance(g1);
    return dist.nearestPoints(g2);
  }

  late STRtree<FacetSequence> _cachedTree;

  final Geometry _baseGeometry;

  IndexedFacetDistance(this._baseGeometry) {
    _cachedTree = FacetSequenceTreeBuilder.build(_baseGeometry);
  }

  double distance(Geometry g) {
    final tree2 = FacetSequenceTreeBuilder.build(g);
    final obj = _cachedTree.nearestNeighbour2(tree2, _FACET_SEQ_DIST)!;
    FacetSequence fs1 = obj[0];
    FacetSequence fs2 = obj[1];
    return fs1.distance(fs2);
  }

  Array<GeometryLocation> nearestLocations(Geometry g) {
    final tree2 = FacetSequenceTreeBuilder.build(g);
    final obj = _cachedTree.nearestNeighbour2(tree2, _FACET_SEQ_DIST)!;
    FacetSequence fs1 = obj[0];
    FacetSequence fs2 = obj[1];
    return fs1.nearestLocations(fs2);
  }

  Array<Coordinate>? nearestPoints(Geometry g) {
    Array<GeometryLocation> minDistanceLocation = nearestLocations(g);
    return toPoints(minDistanceLocation);
  }

  static Array<Coordinate>? toPoints(Array<GeometryLocation>? locations) {
    if (locations == null) {
      return null;
    }

    return [locations[0].getCoordinate(), locations[1].getCoordinate()].toArray();
  }

  bool isWithinDistance(Geometry g, double maxDistance) {
    double envDist = _baseGeometry.getEnvelopeInternal().distance(g.getEnvelopeInternal());
    if (envDist > maxDistance) return false;

    STRtree tree2 = FacetSequenceTreeBuilder.build(g);
    return _cachedTree.isWithinDistance(tree2, _FACET_SEQ_DIST, maxDistance);
  }
}

class FacetSequenceDistance implements ItemDistance<FacetSequence, dynamic> {
  @override
  double distance(final item1, final item2) {
    return item1.item.distance(item2.item);
  }
}
