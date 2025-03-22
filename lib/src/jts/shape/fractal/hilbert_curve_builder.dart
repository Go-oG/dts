 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/shape/geometric_shape_builder.dart';

import 'hilbert_code.dart';

class HilbertCurveBuilder extends GeometricShapeBuilder {
  final int _order = -1;

  HilbertCurveBuilder(super.geomFactory) {
    extent = null;
  }
  void setLevel(int level) {
    numPts = HilbertCode.size(level);
  }

  @override
  Geometry getGeometry() {
    int level = HilbertCode.level(numPts);
    int nPts = HilbertCode.size(level);
    double scale = 1;
    double baseX = 0;
    double baseY = 0;
    if (extent != null) {
      LineSegment baseLine = getSquareBaseLine();
      baseX = baseLine.minX();
      baseY = baseLine.minY();
      double width = baseLine.getLength();
      int maxOrdinate = HilbertCode.maxOrdinate(level);
      scale = width / maxOrdinate;
    }
    Array<Coordinate> pts = Array(nPts);
    for (int i = 0; i < nPts; i++) {
      Coordinate pt = HilbertCode.decode(level, i);
      double x = transform(pt.getX(), scale, baseX);
      double y = transform(pt.getY(), scale, baseY);
      pts[i] = Coordinate(x, y);
    }
    return geomFactory.createLineString2(pts);
  }

  static double transform(double val, double scale, double offset) {
    return (val * scale) + offset;
  }
}
