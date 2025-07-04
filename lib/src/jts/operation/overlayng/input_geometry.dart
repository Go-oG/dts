import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/location.dart';

class InputGeometry {
  Array<Geometry?> geom = Array(2);

  PointOnGeometryLocator? _ptLocatorA;

  PointOnGeometryLocator? _ptLocatorB;

  final Array<bool> _isCollapsed = Array(2);

  InputGeometry(Geometry geomA, Geometry? geomB) {
    geom = [geomA, geomB].toArray();
  }

  bool isSingle() {
    return geom[1] == null;
  }

  int getDimension(int index) {
    if (geom[index] == null) {
      return -1;
    }

    return geom[index]!.getDimension();
  }

  Geometry? getGeometry(int geomIndex) {
    return geom[geomIndex];
  }

  Envelope getEnvelope(int geomIndex) {
    return geom[geomIndex]!.getEnvelopeInternal();
  }

  bool isEmpty(int geomIndex) {
    return geom[geomIndex]!.isEmpty();
  }

  bool isArea(int geomIndex) {
    return (geom[geomIndex] != null) && (geom[geomIndex]!.getDimension() == 2);
  }

  int getAreaIndex() {
    if (getDimension(0) == 2) {
      return 0;
    }

    if (getDimension(1) == 2) {
      return 1;
    }

    return -1;
  }

  bool isLine(int geomIndex) {
    return getDimension(geomIndex) == 1;
  }

  bool isAllPoints() {
    return ((getDimension(0) == 0) && (geom[1] != null)) && (getDimension(1) == 0);
  }

  bool hasPoints() {
    return (getDimension(0) == 0) || (getDimension(1) == 0);
  }

  bool hasEdges(int geomIndex) {
    return (geom[geomIndex] != null) && (geom[geomIndex]!.getDimension() > 0);
  }

  int locatePointInArea(int geomIndex, Coordinate pt) {
    if (_isCollapsed[geomIndex]) {
      return Location.exterior;
    }

    if (getGeometry(geomIndex)!.isEmpty() || _isCollapsed[geomIndex]) {
      return Location.exterior;
    }

    PointOnGeometryLocator ptLocator = getLocator(geomIndex);
    return ptLocator.locate(pt);
  }

  PointOnGeometryLocator getLocator(int geomIndex) {
    if (geomIndex == 0) {
      _ptLocatorA ??= IndexedPointInAreaLocator(getGeometry(geomIndex));

      return _ptLocatorA!;
    } else {
      _ptLocatorB ??= IndexedPointInAreaLocator(getGeometry(geomIndex));
      return _ptLocatorB!;
    }
  }

  void setCollapsed(int geomIndex, bool isGeomCollapsed) {
    _isCollapsed[geomIndex] = isGeomCollapsed;
  }
}
