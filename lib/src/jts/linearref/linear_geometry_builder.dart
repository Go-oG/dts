import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';

class LinearGeometryBuilder {
  final GeometryFactory _geomFact;

  final List<LineString> _lines = [];

  CoordinateList? _coordList;

  bool _ignoreInvalidLines = false;

  bool _fixInvalidLines = false;

  Coordinate? _lastPt;

  LinearGeometryBuilder(this._geomFact);

  void setIgnoreInvalidLines(bool ignoreInvalidLines) {
    _ignoreInvalidLines = ignoreInvalidLines;
  }

  void setFixInvalidLines(bool fixInvalidLines) {
    _fixInvalidLines = fixInvalidLines;
  }

  void add(Coordinate pt) {
    add2(pt, true);
  }

  void add2(Coordinate pt, bool allowRepeatedPoints) {
    _coordList ??= CoordinateList();

    _coordList!.add3(pt, allowRepeatedPoints);
    _lastPt = pt;
  }

  Coordinate? getLastCoordinate() {
    return _lastPt;
  }

  void endLine() {
    if (_coordList == null) {
      return;
    }
    if (_ignoreInvalidLines && (_coordList!.size < 2)) {
      _coordList = null;
      return;
    }
    Array<Coordinate> rawPts = _coordList!.toCoordinateArray();
    Array<Coordinate> pts = rawPts;
    if (_fixInvalidLines) {
      pts = validCoordinateSequence(rawPts);
    }

    _coordList = null;
    LineString? line;
    try {
      line = _geomFact.createLineString2(pts);
    } catch (ex) {
      if (!_ignoreInvalidLines) {
        rethrow;
      }
    }
    if (line != null) {
      _lines.add(line);
    }
  }

  Array<Coordinate> validCoordinateSequence(Array<Coordinate> pts) {
    if (pts.length >= 2) {
      return pts;
    }
    return [pts[0], pts[0]].toArray();
  }

  Geometry getGeometry() {
    endLine();
    return _geomFact.buildGeometry(_lines);
  }
}
