import 'package:dts/src/jts/algorithm/boundary_node_rule.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/point_locator.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/intersection_matrix.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/geometry_graph.dart';
import 'package:dts/src/jts/geomgraph/index/segment_intersector.dart';
import 'package:dts/src/jts/geomgraph/label.dart';
import 'package:dts/src/jts/geomgraph/node.dart';
import 'package:dts/src/jts/geomgraph/node_map.dart';
import 'package:dts/src/jts/operation/boundary_op.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'edge_end_builder.dart';
import 'relate_node.dart';
import 'relate_node_factory.dart';

class RelateComputer {
  LineIntersector li = RobustLineIntersector();

  final ptLocator = PointLocator.empty();

  final List<GeometryGraph> _arg;

  final _nodes = NodeMap(RelateNodeFactory());

  final List _isolatedEdges = [];

  RelateComputer(this._arg);

  IntersectionMatrix computeIM() {
    IntersectionMatrix im = IntersectionMatrix();
    im.set2(Location.exterior, Location.exterior, 2);
    if (!_arg[0].getGeometry()!.getEnvelopeInternal().intersects(_arg[1].getGeometry()!.getEnvelopeInternal())) {
      computeDisjointIM(im, _arg[0].getBoundaryNodeRule()!);
      return im;
    }
    _arg[0].computeSelfNodes(li, false);
    _arg[1].computeSelfNodes(li, false);
    SegmentIntersector intersector = _arg[0].computeEdgeIntersections(_arg[1], li, false);
    computeIntersectionNodes(0);
    computeIntersectionNodes(1);
    copyNodesAndLabels(0);
    copyNodesAndLabels(1);
    labelIsolatedNodes();
    computeProperIntersectionIM(intersector, im);
    final eeBuilder = EdgeEndBuilder();
    final ee0 = eeBuilder.computeEdgeEnds2(_arg[0].getEdgeIterator());
    insertEdgeEnds(ee0);
    final ee1 = eeBuilder.computeEdgeEnds2(_arg[1].getEdgeIterator());
    insertEdgeEnds(ee1);

    labelNodeEdges();
    labelIsolatedEdges(0, 1);
    labelIsolatedEdges(1, 0);
    updateIM(im);
    return im;
  }

  void insertEdgeEnds(List<EdgeEnd> ee) {
    for (var i in ee) {
      _nodes.add(i);
    }
  }

  void computeProperIntersectionIM(SegmentIntersector intersector, IntersectionMatrix im) {
    int dimA = _arg[0].getGeometry()!.getDimension();
    int dimB = _arg[1].getGeometry()!.getDimension();
    bool hasProper = intersector.hasProperIntersection();
    bool hasProperInterior = intersector.hasProperInteriorIntersection();
    if ((dimA == 2) && (dimB == 2)) {
      if (hasProper) im.setAtLeast("212101212");
    } else if ((dimA == 2) && (dimB == 1)) {
      if (hasProper) im.setAtLeast("FFF0FFFF2");

      if (hasProperInterior) im.setAtLeast("1FFFFF1FF");
    } else if ((dimA == 1) && (dimB == 2)) {
      if (hasProper) im.setAtLeast("F0FFFFFF2");

      if (hasProperInterior) im.setAtLeast("1F1FFFFFF");
    } else if ((dimA == 1) && (dimB == 1)) {
      if (hasProperInterior) im.setAtLeast("0FFFFFFFF");
    }
  }

  void copyNodesAndLabels(int argIndex) {
    for (var graphNode in _arg[argIndex].getNodeIterator()) {
      Node newNode = _nodes.addNode(graphNode.getCoordinate());
      newNode.setLabel2(argIndex, graphNode.getLabel()!.getLocation(argIndex));
    }
  }

  void computeIntersectionNodes(int argIndex) {
    for (var e in _arg[argIndex].getEdgeIterator()) {
      int eLoc = e.getLabel()!.getLocation(argIndex);
      for (var ei in e.getEdgeIntersectionList().iterator()) {
        RelateNode n = _nodes.addNode(ei.coord) as RelateNode;
        if (eLoc == Location.boundary) {
          n.setLabelBoundary(argIndex);
        } else if (n.getLabel()!.isNull(argIndex)) {
          n.setLabel2(argIndex, Location.interior);
        }
      }
    }
  }

  void labelIntersectionNodes(int argIndex) {
    for (var e in _arg[argIndex].getEdgeIterator()) {
      int eLoc = e.getLabel()!.getLocation(argIndex);
      for (var ei in e.getEdgeIntersectionList().iterator()) {
        RelateNode n = _nodes.find(ei.coord) as RelateNode;
        if (n.getLabel()!.isNull(argIndex)) {
          if (eLoc == Location.boundary) {
            n.setLabelBoundary(argIndex);
          } else {
            n.setLabel2(argIndex, Location.interior);
          }
        }
      }
    }
  }

  void computeDisjointIM(IntersectionMatrix im, BoundaryNodeRule boundaryNodeRule) {
    Geometry ga = _arg[0].getGeometry()!;
    if (!ga.isEmpty()) {
      im.set2(Location.interior, Location.exterior, ga.getDimension());
      im.set2(Location.boundary, Location.exterior, getBoundaryDim(ga, boundaryNodeRule));
    }
    Geometry gb = _arg[1].getGeometry()!;
    if (!gb.isEmpty()) {
      im.set2(Location.exterior, Location.interior, gb.getDimension());
      im.set2(Location.exterior, Location.boundary, getBoundaryDim(gb, boundaryNodeRule));
    }
  }

  static int getBoundaryDim(Geometry geom, BoundaryNodeRule boundaryNodeRule) {
    if (BoundaryOp.hasBoundary(geom, boundaryNodeRule)) {
      if (geom.getDimension() == 1) return Dimension.P;

      return geom.getBoundaryDimension();
    }
    return Dimension.kFalse;
  }

  void labelNodeEdges() {
    for (var ni in _nodes.iterator()) {
      RelateNode node = ni as RelateNode;
      node.getEdges()!.computeLabelling(_arg);
    }
  }

  void updateIM(IntersectionMatrix im) {
    for (var e in _isolatedEdges) {
      e.updateIM(im);
    }
    for (var ni in _nodes.iterator()) {
      RelateNode node = ni as RelateNode;
      node.updateIM(im);
      node.updateIMFromEdges(im);
    }
  }

  void labelIsolatedEdges(int thisIndex, int targetIndex) {
    for (var e in _arg[thisIndex].getEdgeIterator()) {
      if (e.isIsolated()) {
        labelIsolatedEdge(e, targetIndex, _arg[targetIndex].getGeometry()!);
        _isolatedEdges.add(e);
      }
    }
  }

  void labelIsolatedEdge(Edge e, int targetIndex, Geometry target) {
    if (target.getDimension() > 0) {
      int loc = ptLocator.locate(e.getCoordinate()!, target);
      e.getLabel()!.setAllLocations(targetIndex, loc);
    } else {
      e.getLabel()!.setAllLocations(targetIndex, Location.exterior);
    }
  }

  void labelIsolatedNodes() {
    for (var n in _nodes.iterator()) {
      Label label = n.getLabel()!;
      Assert.isTrue(label.getGeometryCount() > 0, "node with empty label found");
      if (n.isIsolated()) {
        if (label.isNull(0)) {
          labelIsolatedNode(n, 0);
        } else {
          labelIsolatedNode(n, 1);
        }
      }
    }
  }

  void labelIsolatedNode(Node n, int targetIndex) {
    int loc = ptLocator.locate(n.getCoordinate(), _arg[targetIndex].getGeometry()!);
    n.getLabel()!.setAllLocations(targetIndex, loc);
  }
}
