import 'dart:math';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/polygonal.dart';
import 'package:dts/src/jts/shape/geometric_shape_builder.dart';

class RandomPointsBuilder extends GeometricShapeBuilder {
  late Geometry maskPoly;

  PointOnGeometryLocator? _extentLocator;

  RandomPointsBuilder.empty() : super(GeometryFactory());

  RandomPointsBuilder(super.geomFact);

  void setExtent2(Geometry mask) {
    if (mask is! Polygonal) {
      throw ("Only polygonal extents are supported");
    }
    maskPoly = mask;
    setExtent(mask.getEnvelopeInternal());
    _extentLocator = IndexedPointInAreaLocator(mask);
  }

  @override
  Geometry getGeometry() {
    Array<Coordinate> pts = Array(numPts);
    int i = 0;
    while (i < numPts) {
      Coordinate p = createRandomCoord(getExtent()!);
      if ((_extentLocator != null) && (!isInExtent(p))) {
        continue;
      }
      pts[i++] = p;
    }
    return geomFactory.createMultiPoint4(pts);
  }

  bool isInExtent(Coordinate p) {
    if (_extentLocator != null) return _extentLocator!.locate(p) != Location.exterior;

    return getExtent()!.containsCoordinate(p);
  }

  @override
  Coordinate createCoord(double x, double y) {
    Coordinate pt = Coordinate(x, y);
    geomFactory.getPrecisionModel().makePrecise(pt);
    return pt;
  }

  Coordinate createRandomCoord(Envelope env) {
    var random = Random();
    double x = env.minX + (env.width * random.nextDouble());
    double y = env.minY + (env.height * random.nextDouble());
    return createCoord(x, y);
  }
}
