import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_collection.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/geom_filter.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/util/assert.dart';

class InputExtracter implements GeomFilter {
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

  GeomFactory? geomFactory;

  final List<Polygon> _polygons = [];

  List<LineString> lines = [];

  List<Point> points = [];

  int dimension = Dimension.False;

  bool isEmpty() {
    return (_polygons.isEmpty && lines.isEmpty) && points.isEmpty;
  }

  int getDimension() {
    return dimension;
  }

  GeomFactory? getFactory() {
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
    Assert.shouldNeverReachHere2("Invalid dimension: $dim");
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
    if (geom is GeomCollection) {
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
    Assert.shouldNeverReachHere2("Unhandled geometry type: ${geom.geometryType}");
  }

  void recordDimension(int dim) {
    if (dim > dimension) dimension = dim;
  }
}
