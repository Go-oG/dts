 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/distance/discrete_frechet_distance.dart';
import 'package:dts/src/jts/algorithm/distance/discrete_hausdorff_distance.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';

abstract interface class SimilarityMeasure {
  double measure(Geometry g1, Geometry g2);
}

class SimilarityMeasureCombiner {
  static double combine(double measure1, double measure2) {
    return Math.minD(measure1, measure2);
  }
}

class AreaSimilarityMeasure implements SimilarityMeasure {
  AreaSimilarityMeasure();

  @override
  double measure(Geometry g1, Geometry g2) {
    double areaInt = g1.intersection(g2)!.getArea();
    double areaUnion = g1.union2(g2)!.getArea();
    return areaInt / areaUnion;
  }
}

class FrechetSimilarityMeasure implements SimilarityMeasure {
  FrechetSimilarityMeasure();

  @override
  double measure(Geometry g1, Geometry g2) {
    if (g1.geometryType != g2.geometryType) {
      throw ("g1 and g2 are of different type");
    }

    double frechetDistance = DiscreteFrechetDistance.distance(g1, g2);
    if (frechetDistance == 0.0) {
      return 1;
    }

    Envelope env = Envelope.of2(g1.getEnvelopeInternal());
    env.expandToInclude3(g2.getEnvelopeInternal());
    double envDiagSize = HausdorffSimilarityMeasure.diagonalSize(env);
    return 1 - (frechetDistance / envDiagSize);
  }
}

class HausdorffSimilarityMeasure implements SimilarityMeasure {
  HausdorffSimilarityMeasure();

  static const double _DENSIFY_FRACTION = 0.25;

  @override
  double measure(Geometry g1, Geometry g2) {
    double distance = DiscreteHausdorffDistance.distanceS2(g1, g2, _DENSIFY_FRACTION);
    if (distance == 0.0) {
      return 1.0;
    }

    Envelope env = Envelope.of2(g1.getEnvelopeInternal());
    env.expandToInclude3(g2.getEnvelopeInternal());
    double envSize = diagonalSize(env);
    double measure = 1 - (distance / envSize);
    return measure;
  }

  static double diagonalSize(Envelope env) {
    if (env.isNull()) {
      return 0.0;
    }

    double width = env.getWidth();
    double hgt = env.getHeight();
    return Math.sqrt((width * width) + (hgt * hgt));
  }
}
