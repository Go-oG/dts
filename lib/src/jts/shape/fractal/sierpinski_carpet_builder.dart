import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/shape/geometric_shape_builder.dart';

class SierpinskiCarpetBuilder extends GeometricShapeBuilder {
  SierpinskiCarpetBuilder(super.geomFactory);

  static int recursionLevelForSize(int numPts) {
    double pow4 = numPts / 3;
    double exp = Math.log(pow4) / Math.log(4);
    return exp.toInt();
  }

  @override
  Geometry getGeometry() {
    int level = recursionLevelForSize(numPts);
    LineSegment baseLine = getSquareBaseLine();
    Coordinate origin = baseLine.getCoordinate(0);
    final holes = getHoles(level, origin.x, origin.y, getDiameter());
    LinearRing shell = (geomFactory.toGeometry(getSquareExtent()) as Polygon)
        .getExteriorRing();
    return geomFactory.createPolygon(shell, holes);
  }

  List<LinearRing> getHoles(
      int n, double originX, double originY, double width) {
    List<LinearRing> holeList = [];
    addHoles(n, originX, originY, width, holeList);
    return holeList;
  }

  void addHoles(
      int n, double originX, double originY, double width, List holeList) {
    if (n < 0) {
      return;
    }

    int n2 = n - 1;
    double widthThird = width / 3.0;
    addHoles(n2, originX, originY, widthThird, holeList);
    addHoles(n2, originX + widthThird, originY, widthThird, holeList);
    addHoles(n2, originX + (2 * widthThird), originY, widthThird, holeList);
    addHoles(n2, originX, originY + widthThird, widthThird, holeList);
    addHoles(n2, originX + (2 * widthThird), originY + widthThird, widthThird,
        holeList);
    addHoles(n2, originX, originY + (2 * widthThird), widthThird, holeList);
    addHoles(n2, originX + widthThird, originY + (2 * widthThird), widthThird,
        holeList);
    addHoles(n2, originX + (2 * widthThird), originY + (2 * widthThird),
        widthThird, holeList);
    holeList.add(createSquareHole(
        originX + widthThird, originY + widthThird, widthThird));
  }

  LinearRing createSquareHole(double x, double y, double width) {
    final pts = [
      Coordinate(x, y),
      Coordinate(x + width, y),
      Coordinate(x + width, y + width),
      Coordinate(x, y + width),
      Coordinate(x, y),
    ];
    return geomFactory.createLinearRings(pts);
  }
}
