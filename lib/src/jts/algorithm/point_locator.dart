import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'boundary_node_rule.dart';
import 'point_location.dart';

class PointLocator {
  BoundaryNodeRule _boundaryRule = BoundaryNodeRule.ogcSfsBR;
  bool _isIn = false;
  int _numBoundaries = 0;

  PointLocator.empty();

  PointLocator([this._boundaryRule = BoundaryNodeRule.ogcSfsBR]);

  bool intersects(Coordinate p, Geometry geom) {
    return locate(p, geom) != Location.exterior;
  }

  int locate(Coordinate p, Geometry geom) {
    if (geom.isEmpty()) {
      return Location.exterior;
    }

    if (geom is LineString) {
      return _locateOnLineString(p, ((geom)));
    } else if (geom is Polygon) {
      return _locateInPolygon(p, ((geom)));
    }
    _isIn = false;
    _numBoundaries = 0;
    _computeLocation(p, geom);
    if (_boundaryRule.isInBoundary(_numBoundaries)) {
      return Location.boundary;
    }

    if ((_numBoundaries > 0) || _isIn) {
      return Location.interior;
    }

    return Location.exterior;
  }

  void _computeLocation(Coordinate p, Geometry geom) {
    if (geom.isEmpty()) {
      return;
    }

    if (geom is Point) {
      _updateLocationInfo(_locateOnPoint(p, ((geom))));
    }
    if (geom is LineString) {
      _updateLocationInfo(_locateOnLineString(p, ((geom))));
    } else if (geom is Polygon) {
      _updateLocationInfo(_locateInPolygon(p, ((geom))));
    } else if (geom is MultiLineString) {
      MultiLineString ml = geom;
      for (int i = 0; i < ml.getNumGeometries(); i++) {
        LineString l = ml.getGeometryN(i);
        _updateLocationInfo(_locateOnLineString(p, l));
      }
    } else if (geom is MultiPolygon) {
      for (int i = 0; i < geom.getNumGeometries(); i++) {
        Polygon poly = geom.getGeometryN(i);
        _updateLocationInfo(_locateInPolygon(p, poly));
      }
    } else if (geom is GeometryCollection) {
      Iterator geomi = GeometryCollectionIterator(geom);
      while (geomi.moveNext()) {
        Geometry g2 = geomi.current;
        if (g2 != geom) {
          _computeLocation(p, g2);
        }
      }
    }
  }

  void _updateLocationInfo(int loc) {
    if (loc == Location.interior) {
      _isIn = true;
    }

    if (loc == Location.boundary) {
      _numBoundaries++;
    }
  }

  int _locateOnPoint(Coordinate p, Point pt) {
    Coordinate ptCoord = pt.getCoordinate()!;
    if (ptCoord.equals2D(p)) {
      return Location.interior;
    }

    return Location.exterior;
  }

  int _locateOnLineString(Coordinate p, LineString l) {
    if (!l.getEnvelopeInternal().intersectsCoordinate(p)) {
      return Location.exterior;
    }

    CoordinateSequence seq = l.getCoordinateSequence();
    if (p == seq.getCoordinate(0) || p == seq.getCoordinate(seq.size() - 1)) {
      int boundaryCount = (l.isClosed()) ? 2 : 1;
      int loc = (_boundaryRule.isInBoundary(boundaryCount)) ? Location.boundary : Location.interior;
      return loc;
    }
    if (PointLocation.isOnLine2(p, seq)) {
      return Location.interior;
    }
    return Location.exterior;
  }

  int _locateInPolygonRing(Coordinate p, LinearRing ring) {
    if (!ring.getEnvelopeInternal().intersectsCoordinate(p)) {
      return Location.exterior;
    }

    return PointLocation.locateInRing(p, ring.getCoordinates());
  }

  int _locateInPolygon(Coordinate p, Polygon poly) {
    if (poly.isEmpty()) {
      return Location.exterior;
    }

    LinearRing shell = poly.getExteriorRing();
    int shellLoc = _locateInPolygonRing(p, shell);
    if (shellLoc == Location.exterior) {
      return Location.exterior;
    }

    if (shellLoc == Location.boundary) {
      return Location.boundary;
    }

    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      LinearRing hole = poly.getInteriorRingN(i);
      int holeLoc = _locateInPolygonRing(p, hole);
      if (holeLoc == Location.interior) {
        return Location.exterior;
      }

      if (holeLoc == Location.boundary) {
        return Location.boundary;
      }
    }
    return Location.interior;
  }
}
