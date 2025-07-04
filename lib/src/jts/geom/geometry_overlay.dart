import 'package:dts/src/jts/geom/geometry_collection.dart';
import 'package:dts/src/jts/geom/util/geom_collection_mapper.dart';
import 'package:dts/src/jts/geom/util/geometry_mapper.dart';
import 'package:dts/src/jts/operation/overlay/overlay_op.dart';
import 'package:dts/src/jts/operation/overlay/snap/snap_if_needed_overlay_op.dart';
import 'package:dts/src/jts/operation/overlayng/overlay_ngrobust.dart';
import 'package:dts/src/jts/operation/union/unary_union_op.dart';

import 'geometry.dart';

enum GeometryOverlayImpl { ng, old }

class GeometryOverlay {
  static GeometryOverlayImpl _overlayImpl = GeometryOverlayImpl.ng;

  static bool get _isOverlayNG {
    return _overlayImpl == GeometryOverlayImpl.ng;
  }

  static void setOverlayImpl(GeometryOverlayImpl? overlayImpl) {
    if (overlayImpl == null) return;
    _overlayImpl = overlayImpl;
  }

  static Geometry? overlay(Geometry a, Geometry b, OverlayOpCode opCode) {
    if (_isOverlayNG) {
      return OverlayNGRobust.overlay(a, b, opCode);
    } else {
      return SnapIfNeededOverlayOp.overlayOp(a, b, opCode);
    }
  }

  static Geometry? difference(Geometry a, Geometry b) {
    if (a.isEmpty()) return OverlayOp.createEmptyResult(OverlayOpCode.difference, a, b, a.factory);

    if (b.isEmpty()) return a.copy();

    Geometry.checkNotGeometryCollection(a);
    Geometry.checkNotGeometryCollection(b);
    return overlay(a, b, OverlayOpCode.difference);
  }

  static Geometry? intersection(Geometry a, Geometry b) {
    if (a.isEmpty() || b.isEmpty()) {
      return OverlayOp.createEmptyResult(OverlayOpCode.intersection, a, b, a.factory);
    }

    if (a.isGeometryCollection()) {
      final Geometry g2 = b;
      return GeomCollectionMapper.map2(
        a as GeometryCollection,
        MapOpNormal((g) {
          return g.intersection(g2);
        }),
      );
    }
    return overlay(a, b, OverlayOpCode.intersection);
  }

  static Geometry? symDifference(Geometry a, Geometry b) {
    if (a.isEmpty() || b.isEmpty()) {
      if (a.isEmpty() && b.isEmpty())
        return OverlayOp.createEmptyResult(OverlayOpCode.symDifference, a, b, a.factory);

      if (a.isEmpty()) return b.copy();

      if (b.isEmpty()) return a.copy();
    }
    Geometry.checkNotGeometryCollection(a);
    Geometry.checkNotGeometryCollection(b);
    return overlay(a, b, OverlayOpCode.symDifference);
  }

  static Geometry? union2(Geometry a, Geometry b) {
    if (a.isEmpty() || b.isEmpty()) {
      if (a.isEmpty() && b.isEmpty())
        return OverlayOp.createEmptyResult(OverlayOpCode.union, a, b, a.factory);

      if (a.isEmpty()) return b.copy();

      if (b.isEmpty()) return a.copy();
    }
    Geometry.checkNotGeometryCollection(a);
    Geometry.checkNotGeometryCollection(b);
    return overlay(a, b, OverlayOpCode.union);
  }

  static Geometry? union(Geometry a) {
    if (_isOverlayNG) {
      return OverlayNGRobust.union(a);
    } else {
      return UnaryUnionOp.unionS2(a);
    }
  }
}
