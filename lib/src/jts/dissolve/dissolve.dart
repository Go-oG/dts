 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/edgegraph/edge_graph.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';

import '../geom/geometry_component_filter.dart';

class DissolveEdgeGraph extends EdgeGraph {
  @override
  HalfEdge createEdge(Coordinate orig) => DissolveHalfEdge(orig);
}

class DissolveHalfEdge extends MarkHalfEdge {
  bool isStart = false;

  DissolveHalfEdge(super.orig);

  void setStart() {
    isStart = true;
  }
}

class LineDissolver {
  static Geometry dissolve(Geometry g) {
    LineDissolver d = LineDissolver();
    d.add(g);
    return d.getResult();
  }

  Geometry? _result;

  late GeometryFactory factory;

  late final DissolveEdgeGraph _graph;

  final List<Geometry> _lines = [];

  LineDissolver() {
    _graph = DissolveEdgeGraph();
  }

  void add(Geometry geometry) {
    geometry.apply4(
      GeometryComponentFilter2((e) {
        if (e is LineString) {
          _add(e);
        }
      }),
    );
  }

  void add2(List geometries) {
    for (var v in geometries) {
      add(v as Geometry);
    }
  }

  void _add(LineString lineString) {
    CoordinateSequence seq = lineString.getCoordinateSequence();
    bool doneStart = false;
    for (int i = 1; i < seq.size(); i++) {
      DissolveHalfEdge? e = ((_graph.addEdge(seq.getCoordinate(i - 1), seq.getCoordinate(i))) as DissolveHalfEdge?);
      if (e == null) {
        continue;
      }

      if (!doneStart) {
        e.setStart();
        doneStart = true;
      }
    }
  }

  Geometry getResult() {
    if (_result == null) {
      _computeResult();
    }
    return _result!;
  }

  void _computeResult() {
    List edges = _graph.getVertexEdges();

    for (var item in edges) {
      HalfEdge e = item as HalfEdge;
      if (MarkHalfEdge.isMarkedS(e)) {
        continue;
      }
      _process(e);
    }
    _result = factory.buildGeometry(_lines);
  }

  final Stack _nodeEdgeStack = Stack();

  void _process(HalfEdge e) {
    HalfEdge? eNode = e.prevNode();
    eNode ??= e;

    _stackEdges(eNode);
    _buildLines();
  }

  void _buildLines() {
    while (_nodeEdgeStack.isNotEmpty) {
      HalfEdge e = ((_nodeEdgeStack.pop() as HalfEdge));
      if (MarkHalfEdge.isMarkedS(e)) {
        continue;
      }

      _buildLine(e);
    }
  }

  DissolveHalfEdge? _ringStartEdge;

  void _updateRingStartEdge(DissolveHalfEdge e) {
    if (!e.isStart) {
      e = ((e.sym() as DissolveHalfEdge));
      if (!e.isStart) {
        return;
      }
    }
    if (_ringStartEdge == null) {
      _ringStartEdge = e;
      return;
    }
    if (e.orig().compareTo(_ringStartEdge!.orig()) < 0) {
      _ringStartEdge = e;
    }
  }

  void _buildLine(HalfEdge eStart) {
    CoordinateList line = CoordinateList();
    DissolveHalfEdge e = (eStart as DissolveHalfEdge);
    _ringStartEdge = null;
    MarkHalfEdge.markBoth(e);
    line.add3(e.orig().copy(), false);
    while (e.sym().degree() == 2) {
      _updateRingStartEdge(e);
      DissolveHalfEdge eNext = (e.next() as DissolveHalfEdge);
      if (eNext == eStart) {
        _buildRing(_ringStartEdge!);
        return;
      }
      line.add3(eNext.orig().copy(), false);
      e = eNext;
      MarkHalfEdge.markBoth(e);
    }
    line.add3(e.dest().clone(), false);
    _stackEdges(e.sym());
    _addLine(line);
  }

  void _buildRing(HalfEdge eStartRing) {
    CoordinateList line = CoordinateList();
    HalfEdge e = eStartRing;
    line.add3(e.orig().copy(), false);
    while (e.sym().degree() == 2) {
      HalfEdge eNext = e.next()!;
      if (eNext == eStartRing) {
        break;
      }

      line.add3(eNext.orig().copy(), false);
      e = eNext;
    }
    line.add3(e.dest().copy(), false);
    _addLine(line);
  }

  void _addLine(CoordinateList line) {
    _lines.add(factory.createLineString2(line.toCoordinateArray()));
  }

  void _stackEdges(HalfEdge node) {
    HalfEdge e = node;
    do {
      if (!MarkHalfEdge.isMarkedS(e)) {
        _nodeEdgeStack.add(e);
      }

      e = e.oNext()!;
    } while (e != node);
  }
}
