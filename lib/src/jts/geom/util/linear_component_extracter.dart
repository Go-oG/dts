import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_component_filter.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';

class LinearComponentExtracter implements GeometryComponentFilter {
  static List<LineString> getLines2(List<Geometry> geoms, List<LineString> lines) {
    for (var g in geoms) {
      getLines5(g, lines);
    }
    return lines;
  }

  static List<LineString> getLines3(
      List<Geometry> geoms, List<LineString> lines, bool forceToLineString) {
    for (var g in geoms) {
      getLines6(g, lines, forceToLineString);
    }
    return lines;
  }

  static List<LineString> getLines5(Geometry geom, List<LineString> lines) {
    if (geom is LineString) {
      lines.add(geom);
    } else {
      geom.apply4(LinearComponentExtracter(lines));
    }
    return lines;
  }

  static List<LineString> getLines6(Geometry geom, List<LineString> lines, bool forceToLineString) {
    geom.apply4(LinearComponentExtracter.of(lines, forceToLineString));
    return lines;
  }

  static List<LineString> getLines(Geometry geom) {
    return getLines4(geom, false);
  }

  static List<LineString> getLines4(Geometry geom, bool forceToLineString) {
    List<LineString> lines = [];
    geom.apply4(LinearComponentExtracter.of(lines, forceToLineString));
    return lines;
  }

  static Geometry getGeometry(Geometry geom) {
    return geom.factory.buildGeometry(getLines(geom));
  }

  static Geometry getGeometry2(Geometry geom, bool forceToLineString) {
    return geom.factory.buildGeometry(getLines4(geom, forceToLineString));
  }

  final List<LineString> _lines;

  bool _isForcedToLineString = false;

  LinearComponentExtracter(this._lines);

  LinearComponentExtracter.of(this._lines, this._isForcedToLineString);

  void setForceToLineString(bool isForcedToLineString) {
    _isForcedToLineString = isForcedToLineString;
  }

  @override
  void filter(Geometry geom) {
    if (_isForcedToLineString && (geom is LinearRing)) {
      LineString line = geom.factory.createLineString(geom.getCoordinateSequence());
      _lines.add(line);
      return;
    }
    if (geom is LineString) {
      _lines.add(geom);
    }
  }
}
