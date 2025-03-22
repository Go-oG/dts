import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_collection.dart';

import '../geom/geometry_filter.dart';
import 'interior_point_area.dart';
import 'interior_point_line.dart';
import 'interior_point_point.dart';

final class InteriorPoint {
  InteriorPoint._();
  static Coordinate? getInteriorPoint(Geometry geom) {
    if (geom.isEmpty()) {
      return null;
    }
    Coordinate? interiorPt;
    int dim = _dimensionNonEmpty(geom);
    if (dim < 0) {
      return null;
    }
    if (dim == 0) {
      interiorPt = InteriorPointPoint.getInteriorPointS(geom);
    } else if (dim == 1) {
      interiorPt = InteriorPointLine.getInteriorPointS(geom);
    } else {
      interiorPt = InteriorPointArea.getInteriorPointS(geom);
    }
    return interiorPt;
  }

  static int _dimensionNonEmpty(Geometry geom) {
    final dimFilter = _DimensionNonEmptyFilter();
    geom.apply3(dimFilter);
    return dimFilter.getDimension();
  }
}

class _DimensionNonEmptyFilter implements GeometryFilter {
  int dim = -1;

  int getDimension() {
    return dim;
  }

  @override
  void filter(Geometry elem) {
    if (elem is GeometryCollection) {
      return;
    }

    if (!elem.isEmpty()) {
      int elemDim = elem.getDimension();
      if (elemDim > dim) {
        dim = elemDim;
      }
    }
  }
}
