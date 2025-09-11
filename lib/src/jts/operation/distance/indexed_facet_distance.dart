import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/index/strtree/item_distance.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';

import 'facet_sequence.dart';
import 'facet_sequence_tree_builder.dart';
import 'geometry_location.dart';

class IndexedFacetDistance {
  static final _kFacetSeqDist = FacetSequenceDistance();

  static double distance2(Geometry g1, Geometry g2) {
    IndexedFacetDistance dist = IndexedFacetDistance(g1);
    return dist.distance(g2);
  }

  static bool isWithinDistance2(Geometry g1, Geometry g2, double distance) {
    IndexedFacetDistance dist = IndexedFacetDistance(g1);
    return dist.isWithinDistance(g2, distance);
  }

  static List<Coordinate>? nearestPoints2(Geometry g1, Geometry g2) {
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
    final obj = _cachedTree.nearestNeighbour2(tree2, _kFacetSeqDist)!;
    FacetSequence fs1 = obj[0];
    FacetSequence fs2 = obj[1];
    return fs1.distance(fs2);
  }

  List<GeometryLocation> nearestLocations(Geometry g) {
    final tree2 = FacetSequenceTreeBuilder.build(g);
    final obj = _cachedTree.nearestNeighbour2(tree2, _kFacetSeqDist)!;
    FacetSequence fs1 = obj[0];
    FacetSequence fs2 = obj[1];
    return fs1.nearestLocations(fs2);
  }

  List<Coordinate>? nearestPoints(Geometry g) {
    List<GeometryLocation> minDistanceLocation = nearestLocations(g);
    return toPoints(minDistanceLocation);
  }

  static List<Coordinate>? toPoints(List<GeometryLocation>? locations) {
    if (locations == null) {
      return null;
    }

    return [locations[0].getCoordinate(), locations[1].getCoordinate()];
  }

  bool isWithinDistance(Geometry g, double maxDistance) {
    double envDist =
        _baseGeometry.getEnvelopeInternal().distance(g.getEnvelopeInternal());
    if (envDist > maxDistance) return false;

    STRtree tree2 = FacetSequenceTreeBuilder.build(g);
    return _cachedTree.isWithinDistance(tree2, _kFacetSeqDist, maxDistance);
  }
}

class FacetSequenceDistance implements ItemDistance<FacetSequence, dynamic> {
  @override
  double distance(final item1, final item2) {
    return item1.item.distance(item2.item);
  }
}
