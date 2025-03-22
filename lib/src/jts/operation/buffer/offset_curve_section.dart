 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';

class OffsetCurveSection implements Comparable<OffsetCurveSection> {
  static Geometry toGeometry(List<OffsetCurveSection> sections, GeometryFactory geomFactory) {
    if (sections.isEmpty) return geomFactory.createLineString();

    if (sections.length == 1) return geomFactory.createLineString2(sections.get(0).getCoordinates());
    sections.sort();

    Array<LineString> lines = Array(sections.length);
    for (int i = 0; i < sections.size; i++) {
      lines[i] = geomFactory.createLineString2(sections.get(i).getCoordinates());
    }
    return geomFactory.createMultiLineString2(lines);
  }

  static Geometry toLine(List<OffsetCurveSection> sections, GeometryFactory geomFactory) {
    if (sections.size == 0) return geomFactory.createLineString();

    if (sections.size == 1) return geomFactory.createLineString2(sections.get(0).getCoordinates());

    sections.sort();
    CoordinateList pts = CoordinateList();
    bool removeStartPt = false;
    for (int i = 0; i < sections.size; i++) {
      OffsetCurveSection section = sections.get(i);
      bool removeEndPt = false;
      if (i < (sections.size - 1)) {
        double nextStartLoc = sections.get(i + 1)._location;
        removeEndPt = section.isEndInSameSegment(nextStartLoc);
      }
      Array<Coordinate> sectionPts = section.getCoordinates();
      for (int j = 0; j < sectionPts.length; j++) {
        if ((removeStartPt && (j == 0)) || (removeEndPt && (j == (sectionPts.length - 1)))) {
          continue;
        }

        pts.add3(sectionPts[j], false);
      }
      removeStartPt = removeEndPt;
    }
    return geomFactory.createLineString2(pts.toCoordinateArray());
  }

  static OffsetCurveSection create(Array<Coordinate> srcPts, int start, int end, double loc, double locLast) {
    int len = (end - start) + 1;
    if (end <= start) {
      len = (srcPts.length - start) + end;
    }

    Array<Coordinate> sectionPts = Array(len);
    for (int i = 0; i < len; i++) {
      int index = (start + i) % (srcPts.length - 1);
      sectionPts[i] = srcPts[index].copy();
    }
    return OffsetCurveSection(sectionPts, loc, locLast);
  }

  final Array<Coordinate> _sectionPts;

  final double _location;

  final double _locLast;

  OffsetCurveSection(this._sectionPts, this._location, this._locLast);

  Array<Coordinate> getCoordinates() {
    return _sectionPts;
  }

  bool isEndInSameSegment(double nextLoc) {
    int segIndex = _locLast.toInt();
    int nextIndex = nextLoc.toInt();
    return segIndex == nextIndex;
  }

  @override
  int compareTo(OffsetCurveSection section) {
    return Double.compare(_location, section._location);
  }
}
