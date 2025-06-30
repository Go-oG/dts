import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_collection.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/util/assert.dart';

final class InteriorPointArea {
  static Coordinate? getInteriorPointS(Geometry geom) {
    InteriorPointArea intPt = InteriorPointArea(geom);
    return intPt.interiorPoint;
  }

  static double _avg(double a, double b) {
    return (a + b) / 2.0;
  }

  Coordinate? _interiorPoint;
  double _maxWidth = -1;

  InteriorPointArea(Geometry g) {
    _process(g);
  }

  Coordinate? get interiorPoint => _interiorPoint;

  void _process(Geometry geom) {
    if (geom.isEmpty()) {
      return;
    }

    if (geom is Polygon) {
      _processPolygon(geom);
    } else if (geom is GeomCollection) {
      GeomCollection gc = geom;
      for (int i = 0; i < gc.getNumGeometries(); i++) {
        _process(gc.getGeometryN(i));
      }
    }
  }

  void _processPolygon(Polygon polygon) {
    _InteriorPointPolygon intPtPoly = _InteriorPointPolygon(polygon);
    intPtPoly.process();
    double width = intPtPoly.getWidth();
    if (width > _maxWidth) {
      _maxWidth = width;
      _interiorPoint = intPtPoly.getInteriorPoint();
    }
  }
}

class _InteriorPointPolygon {
  final Polygon _polygon;

  late double _interiorPointY;

  double _interiorSectionWidth = 0.0;

  Coordinate? interiorPoint;

  _InteriorPointPolygon(this._polygon) {
    _interiorPointY = _ScanLineYOrdinateFinder.getScanLineYS(_polygon);
  }

  Coordinate? getInteriorPoint() {
    return interiorPoint;
  }

  double getWidth() {
    return _interiorSectionWidth;
  }

  void process() {
    if (_polygon.isEmpty()) {
      return;
    }

    interiorPoint = Coordinate.of(_polygon.getCoordinate()!);
    List<double> crossings = [];
    _scanRing(_polygon.getExteriorRing(), crossings);
    for (int i = 0; i < _polygon.getNumInteriorRing(); i++) {
      _scanRing(_polygon.getInteriorRingN(i), crossings);
    }
    _findBestMidpoint(crossings);
  }

  void _scanRing(LinearRing ring, List<double> crossings) {
    if (!_intersectsHorizontalLine(ring.getEnvelopeInternal(), _interiorPointY)) {
      return;
    }

    CoordinateSequence seq = ring.getCoordinateSequence();
    for (int i = 1; i < seq.size(); i++) {
      Coordinate ptPrev = seq.getCoordinate(i - 1);
      Coordinate pt = seq.getCoordinate(i);
      _addEdgeCrossing(ptPrev, pt, _interiorPointY, crossings);
    }
  }

  void _addEdgeCrossing(Coordinate p0, Coordinate p1, double scanY, List<double> crossings) {
    if (!_intersectsHorizontalLine2(p0, p1, scanY)) {
      return;
    }

    if (!_isEdgeCrossingCounted(p0, p1, scanY)) {
      return;
    }

    double xInt = _intersection(p0, p1, scanY);
    crossings.add(xInt);
  }

  void _findBestMidpoint(List<double> crossings) {
    if (crossings.isEmpty) {
      return;
    }

    Assert.isTrue2(0 == (crossings.length % 2),
        "Interior Point robustness failure: odd number of scanline crossings");

    crossings.sort(Double.compare);

    for (int i = 0; i < crossings.length; i += 2) {
      double x1 = crossings[i];
      double x2 = crossings[i + 1];
      double width = x2 - x1;
      if (width > _interiorSectionWidth) {
        _interiorSectionWidth = width;
        double interiorPointX = InteriorPointArea._avg(x1, x2);
        interiorPoint = Coordinate(interiorPointX, _interiorPointY);
      }
    }
  }

  static bool _isEdgeCrossingCounted(Coordinate p0, Coordinate p1, double scanY) {
    double y0 = p0.y;
    double y1 = p1.y;
    if (y0 == y1) {
      return false;
    }

    if ((y0 == scanY) && (y1 < scanY)) {
      return false;
    }

    if ((y1 == scanY) && (y0 < scanY)) {
      return false;
    }

    return true;
  }

  static double _intersection(Coordinate p0, Coordinate p1, double Y) {
    double x0 = p0.x;
    double x1 = p1.x;
    if (x0 == x1) {
      return x0;
    }

    double segDX = x1 - x0;
    double segDY = p1.y - p0.y;
    double m = segDY / segDX;
    double x = x0 + ((Y - p0.y) / m);
    return x;
  }

  static bool _intersectsHorizontalLine(Envelope env, double y) {
    if (y < env.minY) {
      return false;
    }

    if (y > env.maxY) {
      return false;
    }

    return true;
  }

  static bool _intersectsHorizontalLine2(Coordinate p0, Coordinate p1, double y) {
    if ((p0.y > y) && (p1.y > y)) {
      return false;
    }

    if ((p0.y < y) && (p1.y < y)) {
      return false;
    }

    return true;
  }
}

class _ScanLineYOrdinateFinder {
  static double getScanLineYS(Polygon poly) {
    _ScanLineYOrdinateFinder finder = _ScanLineYOrdinateFinder(poly);
    return finder.getScanLineY();
  }

  final Polygon _poly;

  late double _centreY;

  double _hiY = double.maxFinite;

  double _loY = -double.maxFinite;

  _ScanLineYOrdinateFinder(this._poly) {
    _hiY = _poly.getEnvelopeInternal().maxY;
    _loY = _poly.getEnvelopeInternal().minY;
    _centreY = InteriorPointArea._avg(_loY, _hiY);
  }

  double getScanLineY() {
    _process(_poly.getExteriorRing());
    for (int i = 0; i < _poly.getNumInteriorRing(); i++) {
      _process(_poly.getInteriorRingN(i));
    }
    double scanLineY = InteriorPointArea._avg(_hiY, _loY);
    return scanLineY;
  }

  void _process(LineString line) {
    CoordinateSequence seq = line.getCoordinateSequence();
    for (int i = 0; i < seq.size(); i++) {
      double y = seq.getY(i);
      _updateInterval(y);
    }
  }

  void _updateInterval(double y) {
    if (y <= _centreY) {
      if (y > _loY) {
        _loY = y;
      }
    } else if (y > _centreY) {
      if (y < _hiY) {
        _hiY = y;
      }
    }
  }
}
