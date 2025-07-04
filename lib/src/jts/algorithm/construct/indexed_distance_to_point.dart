import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/operation/distance/indexed_facet_distance.dart';

import 'indexed_point_in_polygons_locator.dart';

class IndexedDistanceToPoint {
  final Geometry _targetGeometry;

  late final IndexedFacetDistance _facetDistance;

  late final IndexedPointInPolygonsLocator _ptLocater;

  IndexedDistanceToPoint(this._targetGeometry) {
    _facetDistance = IndexedFacetDistance(_targetGeometry);
    _ptLocater = IndexedPointInPolygonsLocator(_targetGeometry);
  }

  double distance(Point pt) {
    if (_isInArea(pt)) {
      return 0;
    }
    return _facetDistance.distance(pt);
  }

  bool _isInArea(Point pt) {
    return Location.exterior != _ptLocater.locate(pt.getCoordinate()!);
  }

  Array<Coordinate>? nearestPoints(Point pt) {
    if (_isInArea(pt)) {
      Coordinate p = pt.getCoordinate()!;
      return Array.list([p.copy(), p.copy()]);
    }
    return _facetDistance.nearestPoints(pt);
  }
}
