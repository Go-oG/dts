import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_segment.dart';

import '../geometric_shape_builder.dart';
import 'morton_code.dart';

class MortonCurveBuilder extends GeometricShapeBuilder {
  MortonCurveBuilder(super.geomFactory) {
    extent = null;
  }
  void setLevel(int level) {
    numPts = MortonCode.size(level);
  }

  @override
  Geometry getGeometry() {
    int levelV = MortonCode.level(numPts);
    int nPts = MortonCode.size(levelV);
    double scale = 1;
    double baseX = 0;
    double baseY = 0;
    if (extent != null) {
      LineSegment baseLine = getSquareBaseLine();
      baseX = baseLine.minX();
      baseY = baseLine.minY();
      double width = baseLine.getLength();
      int maxOrdinate = MortonCode.maxOrdinate(levelV);
      scale = width / maxOrdinate;
    }
    Array<Coordinate> pts = Array(nPts);
    for (int i = 0; i < nPts; i++) {
      Coordinate pt = MortonCode.decode(i);
      double x = transform(pt.x, scale, baseX);
      double y = transform(pt.y, scale, baseY);
      pts[i] = Coordinate(x, y);
    }
    return geomFactory.createLineString2(pts);
  }

  static double transform(double val, double scale, double offset) {
    return (val * scale) + offset;
  }
}
