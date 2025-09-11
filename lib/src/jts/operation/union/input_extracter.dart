import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/geometry_filter.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/util/assert.dart';

class InputExtracter implements GeometryFilter {
  static InputExtracter extract2(List<Geometry> geoms) {
    InputExtracter extracter = InputExtracter();
    extracter.add2(geoms);
    return extracter;
  }

  static InputExtracter extract(Geometry geom) {
    InputExtracter extracter = InputExtracter();
    extracter.add(geom);
    return extracter;
  }

  GeometryFactory? geomFactory;

  final List<Polygon> _polygons = [];

  List<LineString> lines = [];

  List<Point> points = [];

  int dimension = Dimension.kFalse;

  bool isEmpty() {
    return (_polygons.isEmpty && lines.isEmpty) && points.isEmpty;
  }

  int getDimension() {
    return dimension;
  }

  GeometryFactory? getFactory() {
    return geomFactory;
  }

  List<Geometry>? getExtract(int dim) {
    switch (dim) {
      case 0:
        return points;
      case 1:
        return lines;
      case 2:
        return _polygons;
    }
    Assert.shouldNeverReachHere("Invalid dimension: $dim");
    return null;
  }

  void add2(List<Geometry> geoms) {
    for (Geometry geom in geoms) {
      add(geom);
    }
  }

  void add(Geometry geom) {
    geomFactory ??= geom.factory;

    geom.apply3(this);
  }

  @override
  void filter(Geometry geom) {
    recordDimension(geom.getDimension());
    if (geom is GeometryCollection) {
      return;
    }
    if (geom.isEmpty()) return;

    if (geom is Polygon) {
      _polygons.add(geom);
      return;
    } else if (geom is LineString) {
      lines.add(geom);
      return;
    } else if (geom is Point) {
      points.add(geom);
      return;
    }
    Assert.shouldNeverReachHere("Unhandled geometry type: ${geom.geometryType}");
  }

  void recordDimension(int dim) {
    if (dim > dimension) dimension = dim;
  }
}
