import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/geometry_filter.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/polygonal.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';
import 'package:dts/src/jts/operation/overlay/snap/snap_if_needed_overlay_op.dart';
import 'package:dts/src/jts/operation/overlayng/overlay_ngrobust.dart';

import '../overlay/overlay_op.dart';
import 'union_strategy.dart';

class _UnionStrategy implements UnionStrategy {
  @override
  bool isDoublePrecision() => true;

  @override
  Geometry? union(Geometry g0, Geometry g1) {
    try {
      return SnapIfNeededOverlayOp.union(g0, g1);
    } catch (ex) {
      return OverlayNGRobust.overlay(g0, g1, OverlayOpCode.union);
    }
  }
}

class CascadedPolygonUnion {
  static const int _strTreeNodeCapacity = 4;

  static final classicUnion = _UnionStrategy();

  static Geometry? union2(List<Geometry> polys) {
    return CascadedPolygonUnion(polys).union();
  }

  static Geometry? union3(List<Geometry> polys, UnionStrategy unionFun) {
    return CascadedPolygonUnion(polys, unionFun).union();
  }

  late List<Geometry> _inputPolys;

  GeometryFactory? geomFactory;

  late UnionStrategy _unionFun;

  int _countRemainder = 0;

  int _countInput = 0;

  CascadedPolygonUnion(List<Geometry>? inputPolys, [UnionStrategy? unionFun]) {
    unionFun ??= classicUnion;
    _unionFun = unionFun;
    _inputPolys = inputPolys ?? [];
    _countInput = _inputPolys.length;
    _countRemainder = _countInput;
  }

  Geometry? union() {
    if (_inputPolys.isEmpty) return null;
    geomFactory = _inputPolys.first.factory;
    STRtree<Geometry> index = STRtree(_strTreeNodeCapacity);
    for (var item in _inputPolys) {
      index.insert(item.getEnvelopeInternal(), item);
    }
    _inputPolys = [];
    return unionTree(index.itemsTree()!);
  }

  Geometry? unionTree(List<Object> geomTree) {
    final geoms = reduceToGeometries(geomTree);
    return binaryUnion(geoms);
  }

  Geometry? binaryUnion(List<Geometry?> geoms) {
    return _binaryUnion(geoms, 0, geoms.length);
  }

  Geometry? _binaryUnion(List<Geometry?> geoms, int start, int end) {
    if ((end - start) <= 1) {
      Geometry? g0 = getGeometry(geoms, start);
      return unionSafe(g0, null);
    } else if ((end - start) == 2) {
      return unionSafe(
          getGeometry(geoms, start), getGeometry(geoms, start + 1));
    } else {
      int mid = (end + start) ~/ 2;
      Geometry? g0 = _binaryUnion(geoms, start, mid);
      Geometry? g1 = _binaryUnion(geoms, mid, end);
      return unionSafe(g0, g1);
    }
  }

  static Geometry? getGeometry(List<Geometry?> list, int index) {
    if (index >= list.length) return null;

    return list[index];
  }

  List<Geometry?> reduceToGeometries(List<Object> geomTree) {
    List<Geometry?> geoms = [];
    for (var o in geomTree) {
      Geometry? geom;
      if (o is List) {
        geom = unionTree(o.cast());
      } else if (o is Geometry) {
        geom = o;
      }
      geoms.add(geom);
    }
    return geoms;
  }

  Geometry? unionSafe(Geometry? g0, Geometry? g1) {
    if ((g0 == null) && (g1 == null)) {
      return null;
    }

    if (g0 == null) {
      return g1!.copy();
    }

    if (g1 == null) return g0.copy();
    _countRemainder--;
    return unionActual(g0, g1);
  }

  Geometry unionActual(Geometry g0, Geometry g1) {
    Geometry union = _unionFun.union(g0, g1)!;
    Geometry unionPoly = restrictToPolygons(union);
    return unionPoly;
  }

  static Geometry restrictToPolygons(Geometry g) {
    if (g is Polygonal) {
      return g;
    }
    List<Polygon> polygons = PolygonExtracter.getPolygons(g);
    if (polygons.length == 1) return polygons.first;
    return g.factory.createMultiPolygon(polygons);
  }
}
