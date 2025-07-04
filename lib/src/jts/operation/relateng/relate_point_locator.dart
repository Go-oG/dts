import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/algorithm/point_location.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/point.dart';

import '../../geom/multi_polygon.dart';
import '../../geom/polygon.dart';
import 'adjacent_edge_locator.dart';
import 'dimension_location.dart';
import 'linear_boundary.dart';

class RelatePointLocator {
  Geometry geom;
  bool isPrepared = false;
  late BoundaryNodeRule _boundaryRule;

  AdjacentEdgeLocator? _adjEdgeLocator;

  Set<Coordinate>? _points;

  List<LineString>? _lines;

  List<Geometry>? _polygons;

  Array<PointOnGeometryLocator?>? _polyLocator;

  LinearBoundary? _lineBoundary;

  bool _isEmpty = false;

  RelatePointLocator(this.geom, [this.isPrepared = false, BoundaryNodeRule? bnRule]) {
    _boundaryRule = bnRule ?? BoundaryNodeRule.ogcSfsBR;
    init(geom);
  }

  void init(Geometry geom) {
    _isEmpty = geom.isEmpty();
    extractElements(geom);
    if (_lines != null) {
      _lineBoundary = LinearBoundary(_lines!, _boundaryRule);
    }
    if (_polygons != null) {
      _polyLocator = (isPrepared)
          ? Array<IndexedPointInAreaLocator>(_polygons!.size)
          : Array<SimplePointInAreaLocator>(_polygons!.size);
    }
  }

  bool hasBoundary() {
    return _lineBoundary!.hasBoundary();
  }

  void extractElements(Geometry geom) {
    if (geom.isEmpty()) {
      return;
    }

    if (geom is Point) {
      addPoint(geom);
    } else if (geom is LineString) {
      addLine(geom);
    } else if ((geom is Polygon) || (geom is MultiPolygon)) {
      addPolygonal(geom);
    } else if (geom is GeometryCollection) {
      for (int i = 0; i < geom.getNumGeometries(); i++) {
        Geometry g = geom.getGeometryN(i);
        extractElements(g);
      }
    }
  }

  void addPoint(Point pt) {
    _points ??= <Coordinate>{};
    _points!.add(pt.getCoordinate()!);
  }

  void addLine(LineString line) {
    _lines ??= [];
    _lines!.add(line);
  }

  void addPolygonal(Geometry polygonal) {
    _polygons ??= [];
    _polygons!.add(polygonal);
  }

  int locate(Coordinate p) {
    return DimensionLocation.location(locateWithDim(p));
  }

  int locateLineEndWithDim(Coordinate p) {
    if (_polygons != null) {
      int locPoly = locateOnPolygons(p, false, null);
      if (locPoly != Location.exterior) {
        return DimensionLocation.locationArea(locPoly);
      }
    }
    return _lineBoundary!.isBoundary(p)
        ? DimensionLocation.LINE_BOUNDARY
        : DimensionLocation.LINE_INTERIOR;
  }

  int locateNode(Coordinate p, Geometry? parentPolygonal) {
    return DimensionLocation.location(locateNodeWithDim(p, parentPolygonal));
  }

  int locateNodeWithDim(Coordinate p, Geometry? parentPolygonal) {
    return locateWithDim2(p, true, parentPolygonal);
  }

  int locateWithDim(Coordinate p) {
    return locateWithDim2(p, false, null);
  }

  int locateWithDim2(Coordinate p, bool isNode, Geometry? parentPolygonal) {
    if (_isEmpty) {
      return DimensionLocation.EXTERIOR;
    }

    if (isNode && ((geom is Polygon) || (geom is MultiPolygon))) {
      return DimensionLocation.AREA_BOUNDARY;
    }

    int dimLoc = computeDimLocation(p, isNode, parentPolygonal);
    return dimLoc;
  }

  int computeDimLocation(Coordinate p, bool isNode, Geometry? parentPolygonal) {
    if (_polygons != null) {
      int locPoly = locateOnPolygons(p, isNode, parentPolygonal);
      if (locPoly != Location.exterior) {
        return DimensionLocation.locationArea(locPoly);
      }
    }
    if (_lines != null) {
      int locLine = locateOnLines(p, isNode);
      if (locLine != Location.exterior) {
        return DimensionLocation.locationLine(locLine);
      }
    }
    if (_points != null) {
      int locPt = locateOnPoints(p);
      if (locPt != Location.exterior) {
        return DimensionLocation.locationPoint(locPt);
      }
    }
    return DimensionLocation.EXTERIOR;
  }

  int locateOnPoints(Coordinate p) {
    if (_points!.contains(p)) {
      return Location.interior;
    }
    return Location.exterior;
  }

  int locateOnLines(Coordinate p, bool isNode) {
    if ((_lineBoundary != null) && _lineBoundary!.isBoundary(p)) {
      return Location.boundary;
    }
    if (isNode) {
      return Location.interior;
    }

    for (LineString line in _lines!) {
      int loc = locateOnLine(p, isNode, line);
      if (loc != Location.exterior) {
        return loc;
      }
    }
    return Location.exterior;
  }

  int locateOnLine(Coordinate p, bool isNode, LineString l) {
    if (!l.getEnvelopeInternal().intersectsCoordinate(p)) {
      return Location.exterior;
    }

    final seq = l.getCoordinateSequence();
    if (PointLocation.isOnLine2(p, seq)) {
      return Location.interior;
    }
    return Location.exterior;
  }

  int locateOnPolygons(Coordinate p, bool isNode, Geometry? parentPolygonal) {
    int numBdy = 0;
    for (int i = 0; i < _polygons!.size; i++) {
      int loc = locateOnPolygonal(p, isNode, parentPolygonal, i);
      if (loc == Location.interior) {
        return Location.interior;
      }
      if (loc == Location.boundary) {
        numBdy += 1;
      }
    }
    if (numBdy == 1) {
      return Location.boundary;
    } else if (numBdy > 1) {
      _adjEdgeLocator ??= AdjacentEdgeLocator(geom);
      return _adjEdgeLocator!.locate(p);
    }
    return Location.exterior;
  }

  int locateOnPolygonal(Coordinate p, bool isNode, Geometry? parentPolygonal, int index) {
    Geometry polygonal = _polygons!.get(index);
    if (isNode && (parentPolygonal == polygonal)) {
      return Location.boundary;
    }
    PointOnGeometryLocator locator = getLocator(index);
    return locator.locate(p);
  }

  PointOnGeometryLocator getLocator(int index) {
    PointOnGeometryLocator? locator = _polyLocator![index];
    if (locator == null) {
      Geometry polygonal = _polygons!.get(index);
      locator =
          (isPrepared) ? IndexedPointInAreaLocator(polygonal) : SimplePointInAreaLocator(polygonal);
      _polyLocator![index] = locator;
    }
    return locator;
  }
}
