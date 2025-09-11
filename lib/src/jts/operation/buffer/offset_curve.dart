import 'package:dts/src/jts/algorithm/distance.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/util/geometry_mapper.dart';
import 'package:dts/src/jts/index/monotone_chain.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'buffer_op.dart';
import 'buffer_parameters.dart';
import 'offset_curve_builder.dart';
import 'offset_curve_section.dart';
import 'segment_mcindex.dart';

class OffsetCurve {
  static const int _kMatchDistanceFactor = 10000;

  static const int _kMinQuadrantSegments = 8;

  static Geometry? getCurve2(Geometry geom, double distance) {
    OffsetCurve oc = OffsetCurve(geom, distance);
    return oc.getCurve();
  }

  static Geometry? getCurve3(Geometry geom, double distance, int quadSegs, int joinStyle, double mitreLimit) {
    BufferParameters bufferParams = BufferParameters.empty();
    if (quadSegs >= 0) bufferParams.setQuadrantSegments(quadSegs);

    if (joinStyle >= 0) bufferParams.setJoinStyle(joinStyle);

    if (mitreLimit >= 0) bufferParams.setMitreLimit(mitreLimit);

    OffsetCurve oc = OffsetCurve(geom, distance, bufferParams);
    return oc.getCurve();
  }

  static Geometry? getCurveJoined(Geometry geom, double distance) {
    OffsetCurve oc = OffsetCurve(geom, distance);
    oc.setJoined(true);
    return oc.getCurve();
  }

  Geometry inputGeom;

  double distance;

  bool _isJoined = false;

  BufferParameters? _bufferParams;

  double _matchDistance = 0;

  late GeometryFactory geomFactory;

  OffsetCurve(this.inputGeom, this.distance, [BufferParameters? bufParams]) {
    _matchDistance = distance.abs() / _kMatchDistanceFactor;
    geomFactory = inputGeom.factory;
    _bufferParams = BufferParameters.empty();
    if (bufParams != null) {
      int quadSegs = bufParams.getQuadrantSegments();
      if (quadSegs < _kMinQuadrantSegments) {
        quadSegs = _kMinQuadrantSegments;
      }
      _bufferParams!.setQuadrantSegments(quadSegs);
      _bufferParams!.setJoinStyle(bufParams.getJoinStyle());
      _bufferParams!.setMitreLimit(bufParams.getMitreLimit());
    }
  }

  void setJoined(bool isJoined) {
    _isJoined = isJoined;
  }

  Geometry? getCurve() {
    return GeometryMapper.flatMap(
      inputGeom,
      1,
      MapOpNormal((geom) {
        if (geom is Point) {
          return null;
        }

        if (geom is Polygon) {
          return computePolygonCurve(geom, distance);
        }
        return computeCurve(geom as LineString, distance);
      }),
    );
  }

  Geometry computePolygonCurve(Polygon poly, double distance) {
    Geometry buffer;
    if (_bufferParams == null) {
      buffer = BufferOp.bufferOp(poly, distance);
    } else {
      buffer = BufferOp.bufferOp3(poly, distance, _bufferParams);
    }
    return toLineString(buffer.getBoundary()!);
  }

  static Geometry toLineString(Geometry geom) {
    if (geom is LinearRing) {
      return geom.factory.createLineString(geom.getCoordinateSequence());
    }
    return geom;
  }

  static List<Coordinate>? rawOffset(LineString line, double distance, [BufferParameters? bufParams]) {
    bufParams ??= BufferParameters.empty();
    final pts = line.getCoordinates();
    final cleanPts = CoordinateArrays.removeRepeatedOrInvalidPoints(pts);
    final ocb = OffsetCurveBuilder(line.factory.getPrecisionModel(), bufParams);
    return ocb.getOffsetCurve(cleanPts, distance);
  }

  Geometry computeCurve(LineString lineGeom, double distance) {
    if ((lineGeom.getNumPoints() < 2) || (lineGeom.getLength() == 0.0)) {
      return geomFactory.createLineString();
    }
    if (distance == 0) {
      return lineGeom.copy();
    }
    if (lineGeom.getNumPoints() == 2) {
      return offsetSegment(lineGeom.getCoordinates(), distance);
    }
    List<OffsetCurveSection> sections = computeSections(lineGeom, distance);
    Geometry offsetCurve;
    if (_isJoined) {
      offsetCurve = OffsetCurveSection.toLine(sections, geomFactory);
    } else {
      offsetCurve = OffsetCurveSection.toGeometry(sections, geomFactory);
    }
    return offsetCurve;
  }

  List<OffsetCurveSection> computeSections(LineString lineGeom, double distance) {
    List<Coordinate> rawCurve = rawOffset(lineGeom, distance, _bufferParams)!;
    List<OffsetCurveSection> sections = [];
    if (rawCurve.isEmpty) {
      return sections;
    }
    Polygon bufferPoly = getBufferOriented(lineGeom, distance, _bufferParams);
    List<Coordinate> shell = bufferPoly.getExteriorRing().getCoordinates();
    computeCurveSections(shell, rawCurve, sections);
    for (int i = 0; i < bufferPoly.getNumInteriorRing(); i++) {
      List<Coordinate> hole = bufferPoly.getInteriorRingN(i).getCoordinates();
      computeCurveSections(hole, rawCurve, sections);
    }
    return sections;
  }

  LineString offsetSegment(List<Coordinate> pts, double distance) {
    LineSegment offsetSeg = LineSegment(pts[0], pts[1]).offset(distance);
    return geomFactory.createLineString2([offsetSeg.p0, offsetSeg.p1]);
  }

  static Polygon getBufferOriented(LineString geom, double distance, BufferParameters? bufParams) {
    Geometry buffer = BufferOp.bufferOp3(geom, distance.abs(), bufParams);
    Polygon bufferPoly = extractMaxAreaPolygon(buffer);
    if (distance < 0) {
      bufferPoly = bufferPoly.reverse();
    }
    return bufferPoly;
  }

  static Polygon extractMaxAreaPolygon(Geometry geom) {
    if (geom.getNumGeometries() == 1) return geom as Polygon;

    double maxArea = 0;
    Polygon? maxPoly;
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Polygon poly = (geom.getGeometryN(i) as Polygon);
      double area = poly.getArea();
      if ((maxPoly == null) || (area > maxArea)) {
        maxPoly = poly;
        maxArea = area;
      }
    }
    return maxPoly!;
  }

  static const double _kNotInCurve = -1;

  void computeCurveSections(
    List<Coordinate> bufferRingPts,
    List<Coordinate> rawCurve,
    List<OffsetCurveSection> sections,
  ) {
    List<double> rawPosition = List.filled(bufferRingPts.length - 1, 0);
    for (int i = 0; i < rawPosition.length; i++) {
      rawPosition[i] = _kNotInCurve;
    }
    SegmentMCIndex bufferSegIndex = SegmentMCIndex(bufferRingPts);
    int bufferFirstIndex = -1;
    double minRawPosition = -1;
    for (int i = 0; i < (rawCurve.length - 1); i++) {
      int minBufferIndexForSeg = matchSegments(
        rawCurve[i],
        rawCurve[i + 1],
        i,
        bufferSegIndex,
        bufferRingPts,
        rawPosition,
      );
      if (minBufferIndexForSeg >= 0) {
        double pos = rawPosition[minBufferIndexForSeg];
        if ((bufferFirstIndex < 0) || (pos < minRawPosition)) {
          minRawPosition = pos;
          bufferFirstIndex = minBufferIndexForSeg;
        }
      }
    }
    if (bufferFirstIndex < 0) return;

    extractSections(bufferRingPts, rawPosition, bufferFirstIndex, sections);
  }

  int matchSegments(
    Coordinate raw0,
    Coordinate raw1,
    int rawCurveIndex,
    SegmentMCIndex bufferSegIndex,
    List<Coordinate> bufferPts,
    List<double> rawCurvePos,
  ) {
    Envelope matchEnv = Envelope.of(raw0, raw1);
    matchEnv.expandBy(_matchDistance);
    final matchAction = MatchCurveSegmentAction(
      raw0,
      raw1,
      rawCurveIndex,
      _matchDistance,
      bufferPts,
      rawCurvePos,
    );
    bufferSegIndex.query(matchEnv, matchAction);
    return matchAction.getBufferMinIndex();
  }

  void extractSections(
    List<Coordinate> ringPts,
    List<double> rawCurveLoc,
    int startIndex,
    List<OffsetCurveSection> sections,
  ) {
    int sectionStart = startIndex;
    int sectionCount = 0;
    int sectionEnd;
    do {
      sectionEnd = findSectionEnd(rawCurveLoc, sectionStart, startIndex);
      double location = rawCurveLoc[sectionStart];
      int lastIndex = prev(sectionEnd, rawCurveLoc.length);
      double lastLoc = rawCurveLoc[lastIndex];
      OffsetCurveSection section = OffsetCurveSection.create(ringPts, sectionStart, sectionEnd, location, lastLoc);
      sections.add(section);
      sectionStart = findSectionStart(rawCurveLoc, sectionEnd);
      if ((sectionCount++) > ringPts.length) {
        Assert.shouldNeverReachHere("Too many sections for ring - probable bug");
      }
    } while ((sectionStart != startIndex) && (sectionEnd != startIndex));
  }

  int findSectionStart(List<double> loc, int end) {
    int start = end;
    do {
      int nextV = next(start, loc.length);
      if (loc[start] == _kNotInCurve) {
        start = nextV;
        continue;
      }
      int prevV = prev(start, loc.length);
      if (loc[prevV] == _kNotInCurve) {
        return start;
      }
      if (_isJoined) {
        double locDelta = (loc[start] - loc[prevV]).abs();
        if (locDelta > 1) return start;
      }
      start = nextV;
    } while (start != end);
    return start;
  }

  int findSectionEnd(List<double> loc, int start, int firstStartIndex) {
    int end = start;
    int nextV;
    do {
      nextV = next(end, loc.length);
      if (loc[nextV] == _kNotInCurve) return nextV;

      if (_isJoined) {
        double locDelta = (loc[nextV] - loc[end]).abs();
        if (locDelta > 1) return nextV;
      }
      end = nextV;
    } while ((end != start) && (end != firstStartIndex));
    return end;
  }

  static int next(int i, int size) {
    i += 1;
    return i < size ? i : 0;
  }

  static int prev(int i, int size) {
    i -= 1;
    return i < 0 ? size - 1 : i;
  }
}

class MatchCurveSegmentAction extends MonotoneChainSelectAction {
  final Coordinate _raw0;

  final Coordinate _raw1;

  double _rawLen = 0;

  final int _rawCurveIndex;

  final List<Coordinate> _bufferRingPts;

  double matchDistance;

  final List<double> _rawCurveLoc;

  double _minRawLocation = -1;

  int _bufferRingMinIndex = -1;

  MatchCurveSegmentAction(
    this._raw0,
    this._raw1,
    this._rawCurveIndex,
    this.matchDistance,
    this._bufferRingPts,
    this._rawCurveLoc,
  ) {
    _rawLen = _raw0.distance(_raw1);
  }

  int getBufferMinIndex() {
    return _bufferRingMinIndex;
  }

  @override
  void select2(MonotoneChain mc, int segIndex) {
    double frac = segmentMatchFrac(_bufferRingPts[segIndex], _bufferRingPts[segIndex + 1], _raw0, _raw1, matchDistance);
    if (frac < 0) return;

    double location = _rawCurveIndex + frac;
    _rawCurveLoc[segIndex] = location;
    if ((_minRawLocation < 0) || (location < _minRawLocation)) {
      _minRawLocation = location;
      _bufferRingMinIndex = segIndex;
    }
  }

  double segmentMatchFrac(Coordinate buf0, Coordinate buf1, Coordinate raw0, Coordinate raw1, double matchDistance) {
    if (!isMatch(buf0, buf1, raw0, raw1, matchDistance)) return -1;

    LineSegment seg = LineSegment(raw0, raw1);
    return seg.segmentFraction(buf0);
  }

  bool isMatch(Coordinate buf0, Coordinate buf1, Coordinate raw0, Coordinate raw1, double matchDistance) {
    double bufSegLen = buf0.distance(buf1);
    if (_rawLen <= bufSegLen) {
      if (matchDistance < Distance.pointToSegment(raw0, buf0, buf1)) {
        return false;
      }

      if (matchDistance < Distance.pointToSegment(raw1, buf0, buf1)) {
        return false;
      }
    } else {
      if (matchDistance < Distance.pointToSegment(buf0, raw0, raw1)) {
        return false;
      }

      if (matchDistance < Distance.pointToSegment(buf1, raw0, raw1)) {
        return false;
      }
    }
    return true;
  }
}
