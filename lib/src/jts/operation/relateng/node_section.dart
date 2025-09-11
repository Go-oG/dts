import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/polygon_node_topology.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/geometry.dart';

class NodeSection implements Comparable<NodeSection> {
  static bool isAreaArea(NodeSection a, NodeSection b) {
    return (a.dimension() == Dimension.A) && (b.dimension() == Dimension.A);
  }

  final bool _isA;

  final int _dim;

  int id;

  final int _ringId;

  final bool _isNodeAtVertex;

  final Coordinate _nodePt;

  final Coordinate? _v0;

  final Coordinate? _v1;

  final Geometry? _poly;

  NodeSection(
    this._isA,
    this._dim,
    this.id,
    this._ringId,
    this._poly,
    this._isNodeAtVertex,
    this._v0,
    this._nodePt,
    this._v1,
  );

  Coordinate? getVertex(int i) {
    return i == 0 ? _v0 : _v1;
  }

  Coordinate nodePt() {
    return _nodePt;
  }

  int dimension() {
    return _dim;
  }

  int ringId() {
    return _ringId;
  }

  Geometry? getPolygonal() {
    return _poly;
  }

  bool isShell() {
    return _ringId == 0;
  }

  bool isArea() {
    return _dim == Dimension.A;
  }

  bool isA() {
    return _isA;
  }

  bool isSameGeometry(NodeSection ns) {
    return isA() == ns.isA();
  }

  bool isSamePolygon(NodeSection ns) {
    return (isA() == ns.isA()) && (id == ns.id);
  }

  bool isNodeAtVertex() {
    return _isNodeAtVertex;
  }

  bool isProper() {
    return !_isNodeAtVertex;
  }

  static bool isProper2(NodeSection a, NodeSection b) {
    return a.isProper() && b.isProper();
  }

  @override
  int compareTo(NodeSection o) {
    if (_isA != o._isA) {
      if (_isA) {
        return -1;
      }

      return 1;
    }
    int compDim = Integer.compare(_dim, o._dim);
    if (compDim != 0) {
      return compDim;
    }

    int compId = Integer.compare(id, o.id);
    if (compId != 0) {
      return compId;
    }

    int compRingId = Integer.compare(_ringId, o._ringId);
    if (compRingId != 0) {
      return compRingId;
    }

    int compV0 = compareWithNull(_v0, o._v0);
    if (compV0 != 0) {
      return compV0;
    }

    return compareWithNull(_v1, o._v1);
  }

  static int compareWithNull(Coordinate? v0, Coordinate? v1) {
    if (v0 == null) {
      if (v1 == null) {
        return 0;
      }
      return -1;
    }
    if (v1 == null) {
      return 1;
    }

    return v0.compareTo(v1);
  }
}

class NodeSectionEdgeAngleComparator implements CComparator<NodeSection> {
  @override
  int compare(NodeSection ns1, NodeSection ns2) {
    return PolygonNodeTopology.compareAngle(
        ns1._nodePt, ns1.getVertex(0)!, ns2.getVertex(0)!);
  }
}
