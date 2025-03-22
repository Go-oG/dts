import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';
import 'package:dts/src/jts/geom/multi_point.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'geometry.dart';

abstract interface class GeometryFilter {
  void filter(Geometry geom);
}

class PointExtracter implements GeometryFilter {
  static List<Point> getPoints2(Geometry geom, List<Point> list) {
    if (geom is Point) {
      list.add(geom);
    } else if (geom is GeometryCollection) {
      geom.apply3(PointExtracter(list));
    }
    return list;
  }

  static List<Point> getPoints(Geometry geom) {
    if (geom is Point) {
      return [geom];
    }
    return getPoints2(geom, []);
  }

  final List<Point> _pts;

  PointExtracter(this._pts);

  @override
  void filter(Geometry geom) {
    if (geom is Point) {
      _pts.add(geom);
    }
  }
}

class LineStringExtracter implements GeometryFilter {
  static List<LineString> getLines2(Geometry geom, List<LineString> lines) {
    if (geom is LineString) {
      lines.add(geom);
    } else if (geom is GeometryCollection) {
      geom.apply3(LineStringExtracter(lines));
    }
    return lines;
  }

  static List<LineString> getLines(Geometry geom) {
    return getLines2(geom, []);
  }

  static Geometry getGeometry(Geometry geom) {
    return geom.factory.buildGeometry(getLines(geom));
  }

  List<LineString> comps;

  LineStringExtracter(this.comps);

  @override
  void filter(Geometry geom) {
    if (geom is LineString) {
      comps.add(geom);
    }
  }
}

class PolygonExtracter implements GeometryFilter {
  static List<Polygon> getPolygons2(Geometry geom, List<Polygon> list) {
    if (geom is Polygon) {
      list.add(geom);
    } else if (geom is GeometryCollection) {
      geom.apply3(PolygonExtracter(list));
    }
    return list;
  }

  static List<Polygon> getPolygons(Geometry geom) {
    return getPolygons2(geom, []);
  }

  List<Polygon> comps;

  PolygonExtracter(this.comps);

  @override
  void filter(Geometry geom) {
    if (geom is Polygon) {
      comps.add(geom);
    }
  }
}

class GeometryExtracter implements GeometryFilter {
  static List extract(Geometry geom, Type clz, List list) {
    return extract4(geom, toGeometryType(clz), list);
  }

  static GeometryType? toGeometryType(Type? clz) {
    if (clz == null) {
      return null;
    }
    if (clz == (Point)) return GeometryType.point;
    if (clz == (LineString)) return GeometryType.lineString;
    if (clz == (LinearRing)) return GeometryType.linearRing;
    if (clz == (Polygon)) return GeometryType.polygon;
    if (clz == (MultiPoint)) return GeometryType.multiPoint;
    if (clz == (MultiLineString)) return GeometryType.multiLineString;
    if (clz == (MultiPolygon)) return GeometryType.multiPolygon;
    if (clz == (GeometryCollection)) return GeometryType.collection;

    throw ("Unsupported class");
  }

  static List extract4(Geometry geom, GeometryType? geometryType, List list) {
    if (geom.geometryType == geometryType) {
      list.add(geom);
    } else if (geom is GeometryCollection) {
      geom.apply3(GeometryExtracter.of(geometryType, list));
    }
    return list;
  }

  static List extract2(Geometry geom, Type clz) {
    return extract(geom, clz, []);
  }

  static List extract3(Geometry geom, GeometryType geometryType) {
    return extract4(geom, geometryType, []);
  }

  GeometryType? _geometryType;

  late List _comps;

  GeometryExtracter(Type clz, List comps) {
    _geometryType = toGeometryType(clz);
    _comps = comps;
  }

  GeometryExtracter.of(this._geometryType, this._comps);

  static bool isOfType(Geometry geom, GeometryType? geometryType) {
    if (geom.geometryType == geometryType) return true;

    if ((geometryType == GeometryType.lineString) && (geom.geometryType == GeometryType.linearRing)) {
      return true;
    }

    return false;
  }

  @override
  void filter(Geometry geom) {
    if ((_geometryType == null) || isOfType(geom, _geometryType)) _comps.add(geom);
  }
}
