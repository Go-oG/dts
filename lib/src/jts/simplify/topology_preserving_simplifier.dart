import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_component_filter.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/util/geometry_transformer.dart';

import 'tagged_line_string.dart';
import 'tagged_lines_simplifier.dart';

class TopologyPreservingSimplifier {
  static Geometry? simplify(Geometry geom, double distanceTolerance) {
    final tss = TopologyPreservingSimplifier(geom);
    tss.setDistanceTolerance(distanceTolerance);
    return tss.getResultGeometry();
  }

  Geometry inputGeom;

  final _lineSimplifier = TaggedLinesSimplifier();

  late Map<LineString, TaggedLineString> _linestringMap;

  TopologyPreservingSimplifier(this.inputGeom);

  void setDistanceTolerance(double distanceTolerance) {
    if (distanceTolerance < 0.0) {
      throw ("Tolerance must be non-negative");
    }

    _lineSimplifier.setDistanceTolerance(distanceTolerance);
  }

  Geometry? getResultGeometry() {
    if (inputGeom.isEmpty()) {
      return inputGeom.copy();
    }

    _linestringMap = {};
    inputGeom.apply4(LineStringMapBuilderFilter(this));
    _lineSimplifier.simplify(_linestringMap.values.toList());
    return LineStringTransformer(_linestringMap).transform(inputGeom);
  }
}

class LineStringTransformer extends GeometryTransformer {
  Map<LineString, TaggedLineString> linestringMap;

  LineStringTransformer(this.linestringMap);

  @override
  CoordinateSequence? transformCoordinates(CoordinateSequence coords, Geometry? parent) {
    if (coords.size() == 0) return null;

    if (parent is LineString) {
      TaggedLineString taggedLine = linestringMap[parent]!;
      return createCoordinateSequence(taggedLine.getResultCoordinates());
    }
    return super.transformCoordinates(coords, parent);
  }
}

class LineStringMapBuilderFilter implements GeomComponentFilter {
  TopologyPreservingSimplifier tps;

  LineStringMapBuilderFilter(this.tps);

  @override
  void filter(Geometry geom) {
    if (geom is LineString) {
      if (geom.isEmpty()) return;

      int minSize = (geom.isClosed()) ? 4 : 2;
      bool isRing = (geom is LinearRing) ? true : false;
      TaggedLineString taggedLine = TaggedLineString(geom, minSize, isRing);
      tps._linestringMap[geom] = taggedLine;
    }
  }
}
