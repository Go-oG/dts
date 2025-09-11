import 'package:dts/src/jts/geom/polygon.dart';

import '../../algorithm/locate/point_on_geometry_locator.dart';
import '../../algorithm/point_locator.dart';
import '../../noding/fast_segment_set_intersection_finder.dart';
import '../../noding/segment_string_util.dart';
import '../../operation/predicate/rectangle_contains.dart';
import '../../operation/predicate/rectangle_intersects.dart';
import '../coordinate.dart';
import '../geometry.dart';
import '../lineal.dart';
import '../puntal.dart';
import '../util/component_coordinate_extracter.dart';
import 'prepared_line_string_intersects.dart';
import 'prepared_polygon_contains.dart';
import 'prepared_polygon_predicate.dart';

class PreparedGeomFactory {
  static PreparedGeom prepare(Geometry geom) {
    return PreparedGeomFactory().create(geom);
  }

  PreparedGeom create(Geometry geom) {
    if (geom is Polygon) {
      return PreparedPolygon(geom);
    }
    if (geom is Lineal) {
      return PreparedLineString(geom);
    }
    if (geom is Puntal) {
      return PreparedPoint(geom as Puntal);
    }
    return BasicPreparedGeom(geom);
  }
}

abstract interface class PreparedGeom {
  Geometry getGeom();

  bool contains(Geometry geom);

  bool containsProperly(Geometry geom);

  bool coveredBy(Geometry geom);

  bool covers(Geometry geom);

  bool crosses(Geometry geom);

  bool disjoint(Geometry geom);

  bool intersects(Geometry geom);

  bool overlaps(Geometry geom);

  bool touches(Geometry geom);

  bool within(Geometry geom);
}

class BasicPreparedGeom<T extends Geometry> implements PreparedGeom {
  late final T _baseGeom;
  late final List<Coordinate> _representativePts;

  BasicPreparedGeom(this._baseGeom) {
    _representativePts = ComponentCoordinateExtracter.getCoordinates(_baseGeom);
  }

  @override
  T getGeom() => _baseGeom;

  List<Coordinate> getRepresentativePoints() {
    return _representativePts;
  }

  bool isAnyTargetComponentInTest(Geometry testGeom) {
    PointLocator locator = PointLocator.empty();
    for (var p in _representativePts) {
      if (locator.intersects(p, testGeom)) return true;
    }
    return false;
  }

  bool envelopesIntersect(Geometry g) {
    if (!_baseGeom.getEnvelopeInternal().intersects(g.getEnvelopeInternal())) {
      return false;
    }

    return true;
  }

  bool envelopeCovers(Geometry g) {
    if (!_baseGeom.getEnvelopeInternal().covers(g.getEnvelopeInternal())) {
      return false;
    }

    return true;
  }

  @override
  bool contains(Geometry g) {
    return _baseGeom.contains(g);
  }

  @override
  bool containsProperly(Geometry g) {
    if (!_baseGeom.getEnvelopeInternal().contains(g.getEnvelopeInternal())) {
      return false;
    }

    return _baseGeom.relate2(g, "T**FF*FF*");
  }

  @override
  bool coveredBy(Geometry g) {
    return _baseGeom.coveredBy(g);
  }

  @override
  bool covers(Geometry g) {
    return _baseGeom.covers(g);
  }

  @override
  bool crosses(Geometry g) {
    return _baseGeom.crosses(g);
  }

  @override
  bool disjoint(Geometry g) {
    return !intersects(g);
  }

  @override
  bool intersects(Geometry g) {
    return _baseGeom.intersects(g);
  }

  @override
  bool overlaps(Geometry g) {
    return _baseGeom.overlaps(g);
  }

  @override
  bool touches(Geometry g) {
    return _baseGeom.touches(g);
  }

  @override
  bool within(Geometry g) {
    return _baseGeom.within(g);
  }

  @override
  String toString() {
    return _baseGeom.toString();
  }
}

class PreparedPoint extends BasicPreparedGeom {
  PreparedPoint(Puntal point) : super(point as Geometry);

  @override
  bool intersects(Geometry g) {
    if (!envelopesIntersect(g)) return false;

    return isAnyTargetComponentInTest(g);
  }
}

class PreparedLineString extends BasicPreparedGeom {
  FastSegmentSetIntersectionFinder? _segIntFinder;

  PreparedLineString(super._baseGeom);

  FastSegmentSetIntersectionFinder getIntersectionFinder() {
    _segIntFinder ??= FastSegmentSetIntersectionFinder(SegmentStringUtil.extractSegmentStrings(getGeom()));
    return _segIntFinder!;
  }

  @override
  bool intersects(Geometry g) {
    if (!envelopesIntersect(g)) return false;
    return PreparedLineStringIntersects.intersectsS(this, g);
  }
}

class PreparedPolygon extends BasicPreparedGeom<Polygon> {
  late final bool _isRectangle;
  FastSegmentSetIntersectionFinder? segIntFinder;
  PointOnGeometryLocator? _pia;

  PreparedPolygon(super.baseGeom) {
    _isRectangle = (getGeom()).isRectangle();
  }

  FastSegmentSetIntersectionFinder getIntersectionFinder() {
    segIntFinder ??= FastSegmentSetIntersectionFinder(SegmentStringUtil.extractSegmentStrings(getGeom()));
    return segIntFinder!;
  }

  PointOnGeometryLocator getPointLocator() {
    _pia ??= IndexedPointInAreaLocator(getGeom());
    return _pia!;
  }

  @override
  bool intersects(Geometry g) {
    if (!envelopesIntersect(g)) return false;

    if (_isRectangle) {
      return RectangleIntersects.intersects2(getGeom(), g);
    }
    return PreparedPolygonIntersects.intersectsS(this, g);
  }

  @override
  bool contains(Geometry g) {
    if (!envelopeCovers(g)) return false;

    if (_isRectangle) {
      return RectangleContains.containsS(getGeom(), g);
    }
    return PreparedPolygonContains.containsS(this, g);
  }

  @override
  bool containsProperly(Geometry g) {
    if (!envelopeCovers(g)) return false;

    return PreparedPolygonContainsProperly.containsProperlyS(this, g);
  }

  @override
  bool covers(Geometry g) {
    if (!envelopeCovers(g)) return false;

    if (_isRectangle) {
      return true;
    }
    return PreparedPolygonCovers.coversS(this, g);
  }
}
