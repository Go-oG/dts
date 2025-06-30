import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/point_location.dart';
import 'package:dts/src/jts/algorithm/ray_crossing_counter.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_collection.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/util/linear_component_extracter.dart';
import 'package:dts/src/jts/index/array_list_visitor.dart';
import 'package:dts/src/jts/index/interval_rtree.dart';
import 'package:dts/src/jts/index/item_visitor.dart';

abstract interface class PointOnGeometryLocator {
  int locate(Coordinate p);
}

class SimplePointInAreaLocator implements PointOnGeometryLocator {
  static int locateS(Coordinate p, Geometry geom) {
    if (geom.isEmpty()) {
      return Location.exterior;
    }

    if (!geom.getEnvelopeInternal().intersectsCoordinate(p)) {
      return Location.exterior;
    }

    return _locateInGeometry(p, geom);
  }

  static bool isContained(Coordinate p, Geometry geom) {
    return Location.exterior != locateS(p, geom);
  }

  static int _locateInGeometry(Coordinate p, Geometry geom) {
    if (geom is Polygon) {
      return locatePointInPolygon(p, geom);
    }
    if (geom is GeomCollection) {
      Iterator geomi = GeometryCollectionIterator(geom);
      while (geomi.moveNext()) {
        Geometry g2 = geomi.current as Geometry;
        if (g2 != geom) {
          int loc = _locateInGeometry(p, g2);
          if (loc != Location.exterior) {
            return loc;
          }
        }
      }
    }
    return Location.exterior;
  }

  static int locatePointInPolygon(Coordinate p, Polygon poly) {
    if (poly.isEmpty()) {
      return Location.exterior;
    }

    LinearRing shell = poly.getExteriorRing();
    int shellLoc = _locatePointInRing(p, shell);
    if (shellLoc != Location.interior) {
      return shellLoc;
    }

    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      LinearRing hole = poly.getInteriorRingN(i);
      int holeLoc = _locatePointInRing(p, hole);
      if (holeLoc == Location.boundary) {
        return Location.boundary;
      }

      if (holeLoc == Location.interior) {
        return Location.exterior;
      }
    }
    return Location.interior;
  }

  static bool containsPointInPolygon(Coordinate p, Polygon poly) {
    return Location.exterior != locatePointInPolygon(p, poly);
  }

  static int _locatePointInRing(Coordinate p, LinearRing ring) {
    if (!ring.getEnvelopeInternal().intersectsCoordinate(p)) {
      return Location.exterior;
    }

    return PointLocation.locateInRing(p, ring.getCoordinates());
  }

  Geometry geom;

  SimplePointInAreaLocator(this.geom);

  @override
  int locate(Coordinate p) {
    return SimplePointInAreaLocator.locateS(p, geom);
  }
}

class IndexedPointInAreaLocator implements PointOnGeometryLocator {
  Geometry? geom;

  _IntervalIndexedGeometry? _index;

  IndexedPointInAreaLocator(this.geom);

  @override
  int locate(Coordinate p) {
    if (_index == null) {
      _createIndex();
    }

    RayCrossingCounter rcc = RayCrossingCounter(p);
    _SegmentVisitor visitor = _SegmentVisitor(rcc);
    _index!.query2(p.y, p.y, visitor);
    return rcc.getLocation();
  }

  void _createIndex() {
    if (_index == null) {
      _index = _IntervalIndexedGeometry(geom!);
      geom = null;
    }
  }
}

class _SegmentVisitor implements ItemVisitor<LineSegment> {
  final RayCrossingCounter counter;

  _SegmentVisitor(this.counter);

  @override
  void visitItem(Object item) {
    LineSegment seg = (item) as LineSegment;
    counter.countSegment(seg.getCoordinate(0), seg.getCoordinate(1));
  }
}

class _IntervalIndexedGeometry {
  late final bool _isEmpty;
  final _index = SortedPackedIntervalRTree();

  _IntervalIndexedGeometry(Geometry geom) {
    if (geom.isEmpty()) {
      _isEmpty = true;
    } else {
      _isEmpty = false;
      _init(geom);
    }
  }

  void _init(Geometry geom) {
    List lines = LinearComponentExtracter.getLines(geom);
    for (var item in lines) {
      LineString line = item as LineString;
      if (!line.isClosed()) {
        continue;
      }
      Array<Coordinate> pts = line.getCoordinates();
      _addLine(pts);
    }
  }

  void _addLine(Array<Coordinate> pts) {
    for (int i = 1; i < pts.length; i++) {
      LineSegment seg = LineSegment(pts[i - 1], pts[i]);
      double min = Math.minD(seg.p0.y, seg.p1.y);
      double max = Math.maxD(seg.p0.y, seg.p1.y);
      _index.insert(min, max, seg);
    }
  }

  List query(double min, double max) {
    if (_isEmpty) {
      return [];
    }

    ArrayListVisitor visitor = ArrayListVisitor();
    _index.query(min, max, visitor);
    return visitor.getItems();
  }

  void query2(double min, double max, ItemVisitor visitor) {
    if (_isEmpty) {
      return;
    }

    _index.query(min, max, visitor);
  }
}
