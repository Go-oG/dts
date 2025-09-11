import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_line_string.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/noding/intersection_adder.dart';
import 'package:dts/src/jts/noding/mcindex_noder.dart';
import 'package:dts/src/jts/noding/noded_segment_string.dart';
import 'package:dts/src/jts/noding/noder.dart';
import 'package:dts/src/jts/noding/segment_string.dart';
import 'package:dts/src/jts/noding/snapround/snap_rounding_noder.dart';
import 'package:dts/src/jts/noding/validating_noder.dart';

import 'edge.dart';
import 'edge_merger.dart';
import 'edge_source_info.dart';
import 'line_limiter.dart';
import 'overlay_util.dart';
import 'ring_clipper.dart';

class EdgeNodingBuilder {
  static const int _kMinLimitPts = 20;

  static final bool _kIsNodingValidated = true;

  static Noder createFixedPrecisionNoder(PrecisionModel pm) {
    Noder noder = SnapRoundingNoder(pm);
    return noder;
  }

  static Noder createDoubleingPrecisionNoder(bool doValidation) {
    MCIndexNoder mcNoder = MCIndexNoder();
    LineIntersector li = RobustLineIntersector();
    mcNoder.setSegmentIntersector(IntersectionAdder(li));
    Noder noder = mcNoder;
    if (doValidation) {
      noder = ValidatingNoder(mcNoder);
    }
    return noder;
  }

  PrecisionModel pm;

  final List<NodedSegmentString> _inputEdges = [];

  final Noder? _customNoder;

  Envelope? _clipEnv;

  RingClipper? _clipper;

  LineLimiter? _limiter;

  final List<bool> _hasEdges = List.filled(2, false);

  EdgeNodingBuilder(this.pm, this._customNoder);

  Noder getNoder() {
    if (_customNoder != null) {
      return _customNoder!;
    }

    if (OverlayUtil.isdoubleing(pm)) {
      return createDoubleingPrecisionNoder(_kIsNodingValidated);
    }

    return createFixedPrecisionNoder(pm);
  }

  void setClipEnvelope(Envelope clipEnv) {
    _clipEnv = clipEnv;
    _clipper = RingClipper(clipEnv);
    _limiter = LineLimiter(clipEnv);
  }

  bool hasEdgesFor(int geomIndex) {
    return _hasEdges[geomIndex];
  }

  List<OEdge> build(Geometry geom0, Geometry geom1) {
    add(geom0, 0);
    add(geom1, 1);
    List<OEdge> nodedEdges = node(_inputEdges);
    List<OEdge> mergedEdges = EdgeMerger.merge(nodedEdges);
    return mergedEdges;
  }

  List<OEdge> node(List<NodedSegmentString> segStrings) {
    Noder noder = getNoder();
    noder.computeNodes(segStrings);
    List<SegmentString> nodedSS = noder.getNodedSubstrings()!;
    List<OEdge> edges = createEdges(nodedSS);
    return edges;
  }

  List<OEdge> createEdges(List<SegmentString> segStrings) {
    List<OEdge> edges = [];
    for (SegmentString ss in segStrings) {
      final pts = ss.getCoordinates();
      if (OEdge.isCollapsed(pts)) {
        continue;
      }

      EdgeSourceInfo info = ss.getData() as EdgeSourceInfo;
      _hasEdges[info.getIndex()] = true;
      edges.add(OEdge(ss.getCoordinates(), info));
    }
    return edges;
  }

  void add(Geometry? g, int geomIndex) {
    if (g == null || g.isEmpty()) return;

    if (isClippedCompletely(g.getEnvelopeInternal())) return;

    if (g is Polygon) {
      addPolygon(g, geomIndex);
    } else if (g is LineString) {
      addLine2(g, geomIndex);
    } else if (g is MultiLineString) {
      addCollection(g, geomIndex);
    } else if (g is MultiPolygon) {
      addCollection(g, geomIndex);
    } else if (g is GeometryCollection) {
      addGeometryCollection(g, geomIndex, g.getDimension());
    }
  }

  void addCollection(GeometryCollection gc, int geomIndex) {
    for (int i = 0; i < gc.getNumGeometries(); i++) {
      Geometry g = gc.getGeometryN(i);
      add(g, geomIndex);
    }
  }

  void addGeometryCollection(GeometryCollection gc, int geomIndex, int expectedDim) {
    for (int i = 0; i < gc.getNumGeometries(); i++) {
      Geometry g = gc.getGeometryN(i);
      if (g.getDimension() != expectedDim) {
        throw ArgumentError("Overlay input is mixed-dimension");
      }
      add(g, geomIndex);
    }
  }

  void addPolygon(Polygon poly, int geomIndex) {
    LinearRing shell = poly.getExteriorRing();
    addPolygonRing(shell, false, geomIndex);
    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      LinearRing hole = poly.getInteriorRingN(i);
      addPolygonRing(hole, true, geomIndex);
    }
  }

  void addPolygonRing(LinearRing ring, bool isHole, int index) {
    if (ring.isEmpty()) return;

    if (isClippedCompletely(ring.getEnvelopeInternal())) return;

    List<Coordinate> pts = clip(ring);
    if (pts.length < 2) {
      return;
    }
    int depthDelta = computeDepthDelta(ring, isHole);
    EdgeSourceInfo info = EdgeSourceInfo(index, depthDelta, isHole);
    addEdge(pts, info);
  }

  bool isClippedCompletely(Envelope env) {
    if (_clipEnv == null) {
      return false;
    }

    return _clipEnv!.disjoint(env);
  }

  List<Coordinate> clip(LinearRing ring) {
    List<Coordinate> pts = ring.getCoordinates();
    Envelope env = ring.getEnvelopeInternal();
    if ((_clipper == null) || _clipEnv!.covers(env)) {
      return removeRepeatedPoints(ring);
    }
    return _clipper!.clip(pts);
  }

  static List<Coordinate> removeRepeatedPoints(LineString line) {
    return CoordinateArrays.removeRepeatedPoints(line.getCoordinates());
  }

  static int computeDepthDelta(LinearRing ring, bool isHole) {
    bool isCCW = Orientation.isCCW2(ring.getCoordinateSequence());
    bool isOriented = true;
    if (!isHole) {
      isOriented = !isCCW;
    } else {
      isOriented = isCCW;
    }
    int depthDelta = (isOriented) ? 1 : -1;
    return depthDelta;
  }

  void addLine2(LineString line, int geomIndex) {
    if (line.isEmpty()) return;

    if (isClippedCompletely(line.getEnvelopeInternal())) return;

    if (isToBeLimited(line)) {
      List<List<Coordinate>> sections = limit(line);
      for (List<Coordinate> pts in sections) {
        addLine(pts, geomIndex);
      }
    } else {
      List<Coordinate> ptsNoRepeat = removeRepeatedPoints(line);
      addLine(ptsNoRepeat, geomIndex);
    }
  }

  void addLine(List<Coordinate> pts, int geomIndex) {
    if (pts.length < 2) {
      return;
    }
    EdgeSourceInfo info = EdgeSourceInfo.of(geomIndex);
    addEdge(pts, info);
  }

  void addEdge(List<Coordinate> pts, EdgeSourceInfo info) {
    NodedSegmentString ss = NodedSegmentString(pts, info);
    _inputEdges.add(ss);
  }

  bool isToBeLimited(LineString line) {
    List<Coordinate> pts = line.getCoordinates();
    if (_limiter == null || pts.length <= _kMinLimitPts) {
      return false;
    }
    final env = line.getEnvelopeInternal();
    if (_clipEnv!.covers(env)) {
      return false;
    }
    return true;
  }

  List<List<Coordinate>> limit(LineString line) => _limiter!.limit(line.getCoordinates());
}
