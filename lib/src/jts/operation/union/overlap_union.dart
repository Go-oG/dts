import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/util/geom_combiner.dart';

import 'cascaded_polygon_union.dart';
import 'union_strategy.dart';

class OverlapUnion {
  static Geometry? unionS(Geometry g0, Geometry g1, UnionStrategy unionFun) {
    OverlapUnion union = OverlapUnion(g0, g1, unionFun);
    return union.union();
  }

  late GeometryFactory geomFactory;

  Geometry g0;

  Geometry g1;

  bool _isUnionSafe = false;

  late UnionStrategy unionFun;

  OverlapUnion(this.g0, this.g1, [UnionStrategy? unionFun]) {
    this.unionFun = unionFun ?? CascadedPolygonUnion.classicUnion;
    geomFactory = g0.factory;
  }

  Geometry? union() {
    Envelope overlapEnv = overlapEnvelope(g0, g1);
    if (overlapEnv.isNull) {
      Geometry g0Copy = g0.copy();
      Geometry g1Copy = g1.copy();
      return GeometryCombiner.combine3(g0Copy, g1Copy);
    }
    List<Geometry> disjointPolys = [];
    Geometry g0Overlap = extractByEnvelope(overlapEnv, g0, disjointPolys);
    Geometry g1Overlap = extractByEnvelope(overlapEnv, g1, disjointPolys);
    Geometry unionGeom = unionFull(g0Overlap, g1Overlap)!;
    Geometry? result;
    _isUnionSafe = isBorderSegmentsSame(unionGeom, overlapEnv);
    if (!_isUnionSafe) {
      result = unionFull(g0, g1);
    } else {
      result = combine(unionGeom, disjointPolys);
    }
    return result;
  }

  bool isUnionOptimized() {
    return _isUnionSafe;
  }

  static Envelope overlapEnvelope(Geometry g0, Geometry g1) {
    Envelope g0Env = g0.getEnvelopeInternal();
    Envelope g1Env = g1.getEnvelopeInternal();
    Envelope overlapEnv = g0Env.intersection(g1Env);
    return overlapEnv;
  }

  Geometry? combine(Geometry unionGeom, List<Geometry> disjointPolys) {
    if (disjointPolys.isEmpty) return unionGeom;

    disjointPolys.add(unionGeom);
    return GeometryCombiner.combine2(disjointPolys);
  }

  Geometry extractByEnvelope(Envelope env, Geometry geom, List<Geometry> disjointGeoms) {
    List<Geometry> intersectingGeoms = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry elem = geom.getGeometryN(i);
      if (elem.getEnvelopeInternal().intersects(env)) {
        intersectingGeoms.add(elem);
      } else {
        Geometry copy = elem.copy();
        disjointGeoms.add(copy);
      }
    }
    return geomFactory.buildGeometry(intersectingGeoms);
  }

  Geometry? unionFull(Geometry geom0, Geometry geom1) {
    if ((geom0.getNumGeometries() == 0) && (geom1.getNumGeometries() == 0)) return geom0.copy();

    return unionFun.union(geom0, geom1);
  }

  bool isBorderSegmentsSame(Geometry result, Envelope env) {
    List<LineSegment> segsBefore = extractBorderSegments2(g0, g1, env);
    List<LineSegment> segsAfter = [];
    extractBorderSegments(result, env, segsAfter);
    return isEqual(segsBefore, segsAfter);
  }

  bool isEqual(List<LineSegment> segs0, List<LineSegment> segs1) {
    if (segs0.length != segs1.length) return false;

    Set<LineSegment> segIndex = <LineSegment>{};
    segIndex.addAll(segs0);
    for (LineSegment seg in segs1) {
      if (!segIndex.contains(seg)) {
        return false;
      }
    }
    return true;
  }

  List<LineSegment> extractBorderSegments2(Geometry geom0, Geometry? geom1, Envelope env) {
    List<LineSegment> segs = [];
    extractBorderSegments(geom0, env, segs);
    if (geom1 != null) {
      extractBorderSegments(geom1, env, segs);
    }

    return segs;
  }

  static bool intersects(Envelope env, Coordinate p0, Coordinate p1) {
    return env.intersectsCoordinate(p0) || env.intersectsCoordinate(p1);
  }

  static bool containsProperly2(Envelope env, Coordinate p0, Coordinate p1) {
    return containsProperly(env, p0) && containsProperly(env, p1);
  }

  static bool containsProperly(Envelope env, Coordinate p) {
    if (env.isNull) return false;

    return p.x > env.minX && p.x < env.maxX && p.y > env.minY && p.y < env.maxY;
  }

  static void extractBorderSegments(Geometry geom, Envelope env, List<LineSegment> segs) {
    geom.apply2(_CoordinateSequenceFilter(geom, env, segs));
  }
}

class _CoordinateSequenceFilter implements CoordinateSequenceFilter {
  final Geometry geom;
  final Envelope env;
  final List<LineSegment> segs;

  _CoordinateSequenceFilter(this.geom, this.env, this.segs);

  @override
  void filter(CoordinateSequence seq, int i) {
    if (i <= 0) return;

    Coordinate p0 = seq.getCoordinate(i - 1);
    Coordinate p1 = seq.getCoordinate(i);
    bool isBorder = OverlapUnion.intersects(env, p0, p1) && (!OverlapUnion.containsProperly2(env, p0, p1));
    if (isBorder) {
      LineSegment seg = LineSegment(p0, p1);
      segs.add(seg);
    }
  }

  @override
  bool isDone() => false;

  @override
  bool isGeometryChanged() => false;
}
