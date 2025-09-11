import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';

class OffsetCurveSection implements Comparable<OffsetCurveSection> {
  static Geometry toGeometry(
      List<OffsetCurveSection> sections, GeometryFactory geomFactory) {
    if (sections.isEmpty) return geomFactory.createLineString();

    if (sections.length == 1) {
      return geomFactory.createLineString2(sections[0].getCoordinates());
    }
    sections.sort();

    List<LineString> lines = [];
    for (int i = 0; i < sections.length; i++) {
      lines.add(geomFactory.createLineString2(sections[i].getCoordinates()));
    }
    return geomFactory.createMultiLineString(lines);
  }

  static Geometry toLine(
      List<OffsetCurveSection> sections, GeometryFactory geomFactory) {
    if (sections.isEmpty) return geomFactory.createLineString();

    if (sections.length == 1) {
      return geomFactory.createLineString2(sections.first.getCoordinates());
    }

    sections.sort();
    CoordinateList pts = CoordinateList();
    bool removeStartPt = false;
    for (int i = 0; i < sections.length; i++) {
      OffsetCurveSection section = sections[i];
      bool removeEndPt = false;
      if (i < (sections.length - 1)) {
        double nextStartLoc = sections[i + 1].location;
        removeEndPt = section.isEndInSameSegment(nextStartLoc);
      }
      List<Coordinate> sectionPts = section.getCoordinates();
      for (int j = 0; j < sectionPts.length; j++) {
        if ((removeStartPt && (j == 0)) ||
            (removeEndPt && (j == (sectionPts.length - 1)))) {
          continue;
        }

        pts.add3(sectionPts[j], false);
      }
      removeStartPt = removeEndPt;
    }
    return geomFactory.createLineString2(pts.toCoordinateList());
  }

  static OffsetCurveSection create(
      List<Coordinate> srcPts, int start, int end, double loc, double locLast) {
    int len = (end - start) + 1;
    if (end <= start) {
      len = (srcPts.length - start) + end;
    }

    List<Coordinate> sectionPts = [];
    for (int i = 0; i < len; i++) {
      int index = (start + i) % (srcPts.length - 1);
      sectionPts.add(srcPts[index].copy());
    }
    return OffsetCurveSection(sectionPts, loc, locLast);
  }

  final List<Coordinate> _sectionPts;

  final double location;

  final double _locLast;

  OffsetCurveSection(this._sectionPts, this.location, this._locLast);

  List<Coordinate> getCoordinates() => _sectionPts;

  bool isEndInSameSegment(double nextLoc) {
    int segIndex = _locLast.toInt();
    int nextIndex = nextLoc.toInt();
    return segIndex == nextIndex;
  }

  @override
  int compareTo(OffsetCurveSection section) {
    return location.compareTo(section.location);
  }
}
