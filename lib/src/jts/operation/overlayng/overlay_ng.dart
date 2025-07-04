import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';
import 'package:dts/src/jts/noding/noder.dart';
import 'package:dts/src/jts/operation/overlay/overlay_op.dart';

import 'edge.dart';
import 'edge_noding_builder.dart';
import 'elevation_model.dart';
import 'input_geometry.dart';
import 'intersection_point_builder.dart';
import 'line_builder.dart';
import 'overlay_edge.dart';
import 'overlay_graph.dart';
import 'overlay_label.dart';
import 'overlay_labeller.dart';
import 'overlay_mixed_points.dart';
import 'overlay_points.dart';
import 'overlay_util.dart';
import 'polygon_builder.dart';

class OverlayNG {
  static final bool strictModeDefault = false;

  static bool isResultOfOpPoint(OverlayLabel label, OverlayOpCode opCode) {
    int loc0 = label.getLocation(0);
    int loc1 = label.getLocation(1);
    return isResultOfOp(opCode, loc0, loc1);
  }

  static bool isResultOfOp(OverlayOpCode overlayOpCode, int loc0, int loc1) {
    if (loc0 == Location.boundary) loc0 = Location.interior;

    if (loc1 == Location.boundary) loc1 = Location.interior;

    switch (overlayOpCode) {
      case OverlayOpCode.intersection:
        return (loc0 == Location.interior) && (loc1 == Location.interior);
      case OverlayOpCode.union:
        return (loc0 == Location.interior) || (loc1 == Location.interior);
      case OverlayOpCode.difference:
        return (loc0 == Location.interior) && (loc1 != Location.interior);
      case OverlayOpCode.symDifference:
        return ((loc0 == Location.interior) && (loc1 != Location.interior)) ||
            ((loc0 != Location.interior) && (loc1 == Location.interior));
    }
    return false;
  }

  static Geometry overlay3(
      Geometry geom0, Geometry geom1, OverlayOpCode opCode, PrecisionModel pm) {
    OverlayNG ov = OverlayNG(geom0, geom1, pm, opCode);
    Geometry geomOv = ov.getResult();
    return geomOv;
  }

  static Geometry overlay4(
      Geometry geom0, Geometry geom1, OverlayOpCode opCode, PrecisionModel pm, Noder noder) {
    OverlayNG ov = OverlayNG(geom0, geom1, pm, opCode);
    ov.setNoder(noder);
    Geometry geomOv = ov.getResult();
    return geomOv;
  }

  static Geometry overlay2(Geometry geom0, Geometry geom1, OverlayOpCode opCode, Noder noder) {
    OverlayNG ov = OverlayNG(geom0, geom1, null, opCode);
    ov.setNoder(noder);
    Geometry geomOv = ov.getResult();
    return geomOv;
  }

  static Geometry overlay(Geometry geom0, Geometry geom1, OverlayOpCode opCode) {
    OverlayNG ov = OverlayNG.of2(geom0, geom1, opCode);
    return ov.getResult();
  }

  static Geometry union(Geometry geom, PrecisionModel? pm) {
    OverlayNG ov = OverlayNG.of(geom, pm);
    Geometry geomOv = ov.getResult();
    return geomOv;
  }

  static Geometry union2(Geometry geom, PrecisionModel? pm, Noder noder) {
    OverlayNG ov = OverlayNG.of(geom, pm);
    ov.setNoder(noder);
    ov.setStrictMode(true);
    Geometry geomOv = ov.getResult();
    return geomOv;
  }

  OverlayOpCode opCode;

  late InputGeometry _inputGeom;

  late GeometryFactory geomFact;

  PrecisionModel? pm;

  Noder? noder;

  bool _isStrictMode = strictModeDefault;

  bool _isOptimized = true;

  bool _isAreaResultOnly = false;

  bool _isOutputEdges = false;

  bool _isOutputResultEdges = false;

  bool _isOutputNodedEdges = false;

  OverlayNG(Geometry geom0, Geometry? geom1, this.pm, this.opCode) {
    geomFact = geom0.factory;
    _inputGeom = InputGeometry(geom0, geom1);
  }

  OverlayNG.of2(Geometry geom0, Geometry geom1, OverlayOpCode opCode)
      : this(geom0, geom1, geom0.factory.getPrecisionModel(), opCode);

  OverlayNG.of(Geometry geom, PrecisionModel? pm) : this(geom, null, pm, OverlayOpCode.union);

  void setStrictMode(bool isStrictMode) {
    _isStrictMode = isStrictMode;
  }

  void setOptimized(bool isOptimized) {
    _isOptimized = isOptimized;
  }

  void setAreaResultOnly(bool isAreaResultOnly) {
    _isAreaResultOnly = isAreaResultOnly;
  }

  void setOutputEdges(bool isOutputEdges) {
    _isOutputEdges = isOutputEdges;
  }

  void setOutputNodedEdges(bool isOutputNodedEdges) {
    _isOutputEdges = true;
    _isOutputNodedEdges = isOutputNodedEdges;
  }

  void setOutputResultEdges(bool isOutputResultEdges) {
    _isOutputResultEdges = isOutputResultEdges;
  }

  void setNoder(Noder noder) {
    this.noder = noder;
  }

  Geometry getResult() {
    if (OverlayUtil.isEmptyResult(
        opCode, _inputGeom.getGeometry(0), _inputGeom.getGeometry(1), pm)) {
      return createEmptyResult();
    }
    ElevationModel elevModel =
        ElevationModel.create(_inputGeom.getGeometry(0)!, _inputGeom.getGeometry(1));
    Geometry? result;
    if (_inputGeom.isAllPoints()) {
      result =
          OverlayPoints.overlay(opCode, _inputGeom.getGeometry(0)!, _inputGeom.getGeometry(1)!, pm);
    } else if ((!_inputGeom.isSingle()) && _inputGeom.hasPoints()) {
      result = OverlayMixedPoints.overlay(
          opCode, _inputGeom.getGeometry(0)!, _inputGeom.getGeometry(1)!, pm);
    } else {
      result = computeEdgeOverlay();
    }
    elevModel.populateZ(result);
    return result;
  }

  Geometry computeEdgeOverlay() {
    List<OEdge> edges = nodeEdges();
    OverlayGraph graph = buildGraph(edges);
    if (_isOutputNodedEdges) {
      return OverlayUtil.toLines(graph, _isOutputEdges, geomFact);
    }
    labelGraph(graph);
    if (_isOutputEdges || _isOutputResultEdges) {
      return OverlayUtil.toLines(graph, _isOutputEdges, geomFact);
    }
    Geometry result = extractResult(opCode, graph);
    if (OverlayUtil.isdoubleing(pm)) {
      bool isAreaConsistent = OverlayUtil.isResultAreaConsistent(
        _inputGeom.getGeometry(0)!,
        _inputGeom.getGeometry(1)!,
        opCode,
        result,
      );
      if (!isAreaConsistent) {
        throw TopologyException("Result area inconsistent with overlay operation");
      }
    }
    return result;
  }

  List<OEdge> nodeEdges() {
    final nodingBuilder = EdgeNodingBuilder(pm!, noder);
    if (_isOptimized) {
      Envelope? clipEnv = OverlayUtil.clippingEnvelope(opCode, _inputGeom, pm);
      if (clipEnv != null) {
        nodingBuilder.setClipEnvelope(clipEnv);
      }
    }
    List<OEdge> mergedEdges =
        nodingBuilder.build(_inputGeom.getGeometry(0)!, _inputGeom.getGeometry(1)!);
    _inputGeom.setCollapsed(0, !nodingBuilder.hasEdgesFor(0));
    _inputGeom.setCollapsed(1, !nodingBuilder.hasEdgesFor(1));
    return mergedEdges;
  }

  OverlayGraph buildGraph(List<OEdge> edges) {
    OverlayGraph graph = OverlayGraph();
    for (OEdge e in edges) {
      graph.addEdge(e.getCoordinates(), e.createLabel());
    }
    return graph;
  }

  void labelGraph(OverlayGraph graph) {
    final labeller = OverlayLabeller(graph, _inputGeom);
    labeller.computeLabelling();
    labeller.markResultAreaEdges(opCode);
    labeller.unmarkDuplicateEdgesFromResultArea();
  }

  Geometry extractResult(OverlayOpCode opCode, OverlayGraph graph) {
    bool isAllowMixedIntResult = !_isStrictMode;
    List<OverlayEdge> resultAreaEdges = graph.getResultAreaEdges();
    final polyBuilder = NgPolygonBuilder(resultAreaEdges, geomFact);
    List<Polygon> resultPolyList = polyBuilder.getPolygons();
    bool hasResultAreaComponents = resultPolyList.isNotEmpty;
    List<LineString>? resultLineList;
    List<Point>? resultPointList;
    if (!_isAreaResultOnly) {
      bool allowResultLines = (((!hasResultAreaComponents) || isAllowMixedIntResult) ||
              (opCode == OverlayOpCode.symDifference)) ||
          (opCode == OverlayOpCode.union);
      if (allowResultLines) {
        final lineBuilder =
            NgLineBuilder(_inputGeom, graph, hasResultAreaComponents, opCode, geomFact);
        lineBuilder.setStrictMode(_isStrictMode);
        resultLineList = lineBuilder.getLines();
      }
      bool hasResultComponents = hasResultAreaComponents || (resultLineList!.isNotEmpty);
      bool allowResultPoints = (!hasResultComponents) || isAllowMixedIntResult;
      if ((opCode == OverlayOpCode.intersection) && allowResultPoints) {
        final pointBuilder = IntersectionPointBuilder(graph, geomFact);
        pointBuilder.setStrictMode(_isStrictMode);
        resultPointList = pointBuilder.getPoints();
      }
    }
    if ((isEmpty(resultPolyList) && isEmpty(resultLineList)) && isEmpty(resultPointList)) {
      return createEmptyResult();
    }

    return OverlayUtil.createResultGeometry(
        resultPolyList, resultLineList!, resultPointList!, geomFact);
  }

  static bool isEmpty(List? list) {
    return (list == null) || (list.isEmpty);
  }

  Geometry createEmptyResult() {
    return OverlayUtil.createEmptyResult(
      OverlayUtil.resultDimension(opCode, _inputGeom.getDimension(0), _inputGeom.getDimension(1)),
      geomFact,
    );
  }
}
