 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/envelope.dart';

class LineLimiter {
  final Envelope _limitEnv;

  CoordinateList? _ptList;

  Coordinate? _lastOutside;

  List<Array<Coordinate>>? _sections;

  LineLimiter(this._limitEnv);

  List<Array<Coordinate>> limit(Array<Coordinate> pts) {
    _lastOutside = null;
    _ptList = null;
    _sections = [];
    for (int i = 0; i < pts.length; i++) {
      Coordinate p = pts[i];
      if (_limitEnv.intersects(p)) {
        addPoint(p);
      } else {
        addOutside(p);
      }
    }
    finishSection();
    return _sections!;
  }

  void addPoint(Coordinate? p) {
    if (p == null) return;

    startSection();
    _ptList!.add3(p, false);
  }

  void addOutside(Coordinate p) {
    bool segIntersects = isLastSegmentIntersecting(p);
    if (!segIntersects) {
      finishSection();
    } else {
      addPoint(_lastOutside);
      addPoint(p);
    }
    _lastOutside = p;
  }

  bool isLastSegmentIntersecting(Coordinate p) {
    if (_lastOutside == null) {
      if (isSectionOpen()) {
        return true;
      }

      return false;
    }
    return _limitEnv.intersects2(_lastOutside!, p);
  }

  bool isSectionOpen() {
    return _ptList != null;
  }

  void startSection() {
    _ptList ??= CoordinateList();
    if (_lastOutside != null) {
      _ptList!.add3(_lastOutside!, false);
    }
    _lastOutside = null;
  }

  void finishSection() {
    if (_ptList == null) return;

    if (_lastOutside != null) {
      _ptList!.add3(_lastOutside!, false);
      _lastOutside = null;
    }
    Array<Coordinate> section = _ptList!.toCoordinateArray();
    _sections!.add(section);
    _ptList = null;
  }
}
