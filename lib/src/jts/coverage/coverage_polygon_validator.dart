import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/noding/mcindex_segment_set_mutual_intersector.dart';

import '../geom/geometry_filter.dart';
import 'coverage_polygon.dart';
import 'coverage_ring.dart';
import 'invalid_segment_detector.dart';

class CoveragePolygonValidator {
  static Geometry validateS(Geometry targetPolygon, Array<Geometry> adjPolygons) {
    CoveragePolygonValidator v = CoveragePolygonValidator(targetPolygon, adjPolygons);
    return v.validate();
  }

  static Geometry validateS2(Geometry targetPolygon, Array<Geometry> adjPolygons, double gapWidth) {
    CoveragePolygonValidator v = CoveragePolygonValidator(targetPolygon, adjPolygons);
    v.setGapWidth(gapWidth);
    return v.validate();
  }

  late Geometry _targetGeom;
  late GeometryFactory geomFactory;
  late Array<Geometry> _adjGeoms;

  double _gapWidth = 0.0;

  List<CoveragePolygon>? _adjCovPolygons;

  CoveragePolygonValidator(Geometry geom, Array<Geometry> adjGeoms) {
    _targetGeom = geom;
    _adjGeoms = adjGeoms;
    geomFactory = _targetGeom.factory;
  }

  void setGapWidth(double gapWidth) {
    _gapWidth = gapWidth;
  }

  Geometry validate() {
    List<Polygon> adjPolygons = _extractPolygons(_adjGeoms);
    _adjCovPolygons = _toCoveragePolygons(adjPolygons);
    List<CoverageRing> targetRings = CoverageRing.createRings(_targetGeom);
    List<CoverageRing> adjRings = CoverageRing.createRings2(adjPolygons);
    Envelope targetEnv = _targetGeom.getEnvelopeInternal().copy();
    targetEnv.expandBy(_gapWidth);
    _checkTargetRings(targetRings, adjRings, targetEnv);
    return _createInvalidLines(targetRings);
  }

  static List<CoveragePolygon> _toCoveragePolygons(List<Polygon> polygons) {
    List<CoveragePolygon> covPolys = [];
    for (Polygon poly in polygons) {
      covPolys.add(CoveragePolygon(poly));
    }
    return covPolys;
  }

  void _checkTargetRings(List<CoverageRing> targetRings, List<CoverageRing> adjRings, Envelope targetEnv) {
    _markMatchedSegments(targetRings, adjRings, targetEnv);
    if (CoverageRing.isKnownS(targetRings)) {
      return;
    }

    _markInvalidInteractingSegments(targetRings, adjRings, _gapWidth);
    _markInvalidInteriorSegments(targetRings, _adjCovPolygons!);
  }

  static List<Polygon> _extractPolygons(Array<Geometry> geoms) {
    List<Polygon> polygons = [];
    for (var geom in geoms) {
      PolygonExtracter.getPolygons2(geom, polygons);
    }
    return polygons;
  }

  Geometry _createEmptyResult() {
    return geomFactory.createLineString();
  }

  void _markMatchedSegments(List<CoverageRing> targetRings, List<CoverageRing> adjRngs, Envelope targetEnv) {
    Map<_CoverageRingSegment, _CoverageRingSegment> segmentMap = {};
    _markMatchedSegments2(targetRings, targetEnv, segmentMap);
    _markMatchedSegments2(adjRngs, targetEnv, segmentMap);
  }

  void _markMatchedSegments2(
    List<CoverageRing> rings,
    Envelope envLimit,
    Map<_CoverageRingSegment, _CoverageRingSegment> segmentMap,
  ) {
    for (CoverageRing ring in rings) {
      for (int i = 0; i < (ring.size() - 1); i++) {
        Coordinate p0 = ring.getCoordinate(i);
        Coordinate p1 = ring.getCoordinate(i + 1);
        if (!envLimit.intersectsCoordinates(p0, p1)) {
          continue;
        }
        _CoverageRingSegment seg = _CoverageRingSegment.create(ring, i);
        if (segmentMap.containsKey(seg)) {
          _CoverageRingSegment segMatch = segmentMap.get(seg)!;
          seg.match(segMatch);
        } else {
          segmentMap.put(seg, seg);
        }
      }
    }
  }

  void _markInvalidInteractingSegments(
      List<CoverageRing> targetRings, List<CoverageRing> adjRings, double distanceTolerance) {
    InvalidSegmentDetector detector = InvalidSegmentDetector(distanceTolerance);
    final segSetMutInt = MCIndexSegmentSetMutualIntersector(targetRings, null, distanceTolerance);
    segSetMutInt.process(adjRings, detector);
  }

  static const _RING_SECTION_STRIDE = 1000;

  void _markInvalidInteriorSegments(List<CoverageRing> targetRings, List<CoveragePolygon> adjCovPolygons) {
    for (CoverageRing ring in targetRings) {
      int stride = _RING_SECTION_STRIDE;
      for (int i = 0; i < (ring.size() - 1); i += stride) {
        int iEnd = i + stride;
        if (iEnd >= ring.size()) {
          iEnd = ring.size() - 1;
        }

        _markInvalidInteriorSection(ring, i, iEnd, adjCovPolygons);
      }
    }
  }

  void _markInvalidInteriorSection(CoverageRing ring, int iStart, int iEnd, List<CoveragePolygon> adjPolygons) {
    Envelope sectionEnv = ring.getEnvelope(iStart, iEnd);
    for (CoveragePolygon adjPoly in adjPolygons) {
      if (adjPoly.intersectsEnv(sectionEnv)) {
        for (int i = iStart; i < iEnd; i++) {
          _markInvalidInteriorSegment(ring, i, adjPoly);
        }
      }
    }
  }

  void _markInvalidInteriorSegment(CoverageRing ring, int i, CoveragePolygon adjPoly) {
    if (ring.isKnown2(i)) {
      return;
    }
    Coordinate p = ring.getCoordinate(i);
    if (adjPoly.contains(p)) {
      ring.markInvalid(i);
      int iPrev = (i == 0) ? ring.size() - 2 : i - 1;
      if (!ring.isKnown2(iPrev)) {
        ring.markInvalid(iPrev);
      }
    }
  }

  Geometry _createInvalidLines(List<CoverageRing> rings) {
    List<LineString> lines = [];
    for (CoverageRing ring in rings) {
      ring.createInvalidLines(geomFactory, lines);
    }
    if (lines.size == 0) {
      return _createEmptyResult();
    } else if (lines.size == 1) {
      return lines.get(0);
    }
    return geomFactory.createMultiLineString(GeometryFactory.toLineStringArray(lines));
  }
}

class _CoverageRingSegment extends LineSegment {
  static _CoverageRingSegment create(CoverageRing ring, int index) {
    Coordinate p0 = ring.getCoordinate(index);
    Coordinate p1 = ring.getCoordinate(index + 1);
    if (ring.isInteriorOnRight()) {
      return _CoverageRingSegment(p0, p1, ring, index);
    } else {
      return _CoverageRingSegment(p1, p0, ring, index);
    }
  }

  CoverageRing? ringForward;

  int indexForward = -1;

  CoverageRing? ringOpp;

  int indexOpp = -1;

  _CoverageRingSegment(Coordinate p0, Coordinate p1, CoverageRing ring, int index) : super(p0, p1) {
    if (p1.compareTo(p0) < 0) {
      super.reverse();
      ringOpp = ring;
      indexOpp = index;
    } else {
      ringForward = ring;
      indexForward = index;
    }
  }

  void match(_CoverageRingSegment seg) {
    bool isInvalid = checkInvalid(seg);
    if (isInvalid) {
      return;
    }
    if (ringForward == null) {
      ringForward = seg.ringForward;
      indexForward = seg.indexForward;
    } else {
      ringOpp = seg.ringOpp;
      indexOpp = seg.indexOpp;
    }
    ringForward!.markMatched(indexForward);
    ringOpp!.markMatched(indexOpp);
  }

  bool checkInvalid(_CoverageRingSegment seg) {
    if ((ringForward != null) && (seg.ringForward != null)) {
      ringForward!.markInvalid(indexForward);
      seg.ringForward!.markInvalid(seg.indexForward);
      return true;
    }
    if ((ringOpp != null) && (seg.ringOpp != null)) {
      ringOpp!.markInvalid(indexOpp);
      seg.ringOpp!.markInvalid(seg.indexOpp);
      return true;
    }
    return false;
  }
}
