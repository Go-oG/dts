import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/label.dart';
import 'package:dts/src/jts/geomgraph/planar_graph.dart';
import 'package:dts/src/jts/noding/fast_noding_validator.dart';
import 'package:dts/src/jts/noding/intersection_adder.dart';
import 'package:dts/src/jts/noding/mcindex_noder.dart';
import 'package:dts/src/jts/noding/noder.dart';
import 'package:dts/src/jts/noding/segment_string.dart';
import 'package:dts/src/jts/operation/buffer/polygon_builder.dart';

import 'buffer_curve_set_builder.dart';
import 'buffer_node_factory.dart';
import 'buffer_parameters.dart';
import 'buffer_subgraph.dart';
import 'subgraph_depth_locater.dart';

class BufferBuilder {
  static int depthDelta(Label label) {
    int lLoc = label.getLocation2(0, Position.left);
    int rLoc = label.getLocation2(0, Position.right);
    if ((lLoc == Location.interior) && (rLoc == Location.exterior)) {
      return 1;
    }
    if ((lLoc == Location.exterior) && (rLoc == Location.interior)) {
      return -1;
    }
    return 0;
  }

  final BufferParameters _bufParams;

  PrecisionModel? _workingPrecisionModel;

  Noder? _workingNoder;

  late GeometryFactory geomFact;

  late PGPlanarGraph _graph;

  final EdgeList _edgeList = EdgeList();

  bool _isInvertOrientation = false;

  BufferBuilder(this._bufParams);

  void setWorkingPrecisionModel(PrecisionModel pm) {
    _workingPrecisionModel = pm;
  }

  void setNoder(Noder noder) {
    _workingNoder = noder;
  }

  void setInvertOrientation(bool isInvertOrientation) {
    _isInvertOrientation = isInvertOrientation;
  }

  Geometry buffer(Geometry g, double distance) {
    var precisionModel = _workingPrecisionModel;
    precisionModel ??= g.getPrecisionModel();

    geomFact = g.factory;
    final curveSetBuilder = BufferCurveSetBuilder(g, distance, precisionModel, _bufParams);
    curveSetBuilder.setInvertOrientation(_isInvertOrientation);
    final bufferSegStrList = curveSetBuilder.getCurves();
    if (bufferSegStrList.isEmpty) {
      return createEmptyResultGeometry();
    }
    bool isNodingValidated = distance == 0.0;
    computeNodedEdges(bufferSegStrList, precisionModel, isNodingValidated);
    _graph = PGPlanarGraph(BufferNodeFactory());
    _graph.addEdges(_edgeList.getEdges());
    List<BufferSubgraph> subgraphList = createSubGraphs(_graph);
    final polyBuilder = PolygonBuilder(geomFact);
    buildSubGraphs(subgraphList, polyBuilder);
    List<Geometry> resultPolyList = polyBuilder.getPolygons();
    if (resultPolyList.isEmpty) {
      return createEmptyResultGeometry();
    }
    Geometry resultGeom = geomFact.buildGeometry(resultPolyList);
    return resultGeom;
  }

  Noder getNoder(PrecisionModel precisionModel) {
    if (_workingNoder != null) {
      return _workingNoder!;
    }

    MCIndexNoder noder = MCIndexNoder();
    LineIntersector li = RobustLineIntersector();
    li.setPrecisionModel(precisionModel);
    noder.setSegmentIntersector(IntersectionAdder(li));
    return noder;
  }

  void computeNodedEdges(
      List<SegmentString> bufferSegStrList, PrecisionModel precisionModel, bool isNodingValidated) {
    Noder noder = getNoder(precisionModel);
    noder.computeNodes(bufferSegStrList);
    final nodedSegStrings = noder.getNodedSubstrings()!;
    if (isNodingValidated) {
      FastNodingValidator nv = FastNodingValidator(nodedSegStrings);
      nv.checkValid();
    }

    for (var segStr in nodedSegStrings) {
      Array<Coordinate> pts = segStr.getCoordinates();
      if ((pts.length == 2) && pts[0].equals2D(pts[1])) continue;

      Label oldLabel = segStr.getData() as Label;
      Edge edge = Edge(segStr.getCoordinates(), Label(oldLabel));
      insertUniqueEdge(edge);
    }
  }

  void insertUniqueEdge(Edge e) {
    Edge? existingEdge = _edgeList.findEqualEdge(e);
    if (existingEdge != null) {
      Label existingLabel = existingEdge.getLabel()!;
      Label labelToMerge = e.getLabel()!;
      if (!existingEdge.isPointwiseEqual(e)) {
        labelToMerge = Label(e.getLabel()!);
        labelToMerge.flip();
      }
      existingLabel.merge(labelToMerge);
      int mergeDelta = depthDelta(labelToMerge);
      int existingDelta = existingEdge.getDepthDelta();
      int newDelta = existingDelta + mergeDelta;
      existingEdge.setDepthDelta(newDelta);
    } else {
      _edgeList.add(e);
      e.setDepthDelta(depthDelta(e.getLabel()!));
    }
  }

  List<BufferSubgraph> createSubGraphs(PGPlanarGraph graph) {
    List<BufferSubgraph> subgraphList = [];
    for (var node in graph.getNodes()) {
      if (!node.isVisited) {
        BufferSubgraph subgraph = BufferSubgraph();
        subgraph.create(node);
        subgraphList.add(subgraph);
      }
    }
    subgraphList.sort();
    return subgraphList.reversed.toList();
  }

  void buildSubGraphs(List<BufferSubgraph> subgraphList, PolygonBuilder polyBuilder) {
    List<BufferSubgraph> processedGraphs = [];
    for (var subgraph in subgraphList) {
      Coordinate p = subgraph.getRightmostCoordinate()!;
      final locater = SubgraphDepthLocater(processedGraphs);
      int outsideDepth = locater.getDepth(p);
      subgraph.computeDepth(outsideDepth);
      subgraph.findResultEdges();
      processedGraphs.add(subgraph);
      polyBuilder.addAll(subgraph.getDirectedEdges(), subgraph.getNodes());
    }
  }

  static Geometry convertSegStrings(Iterator<SegmentString> it) {
    GeometryFactory fact = GeometryFactory();
    List<LineString> lines = [];
    while (it.moveNext()) {
      SegmentString ss = it.current;
      LineString line = fact.createLineString2(ss.getCoordinates());
      lines.add(line);
    }
    return fact.buildGeometry(lines);
  }

  Geometry createEmptyResultGeometry() {
    Geometry emptyGeom = geomFact.createPolygon();
    return emptyGeom;
  }
}
