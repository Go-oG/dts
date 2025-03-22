 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/util/geometry_transformer.dart';

import 'vwline_simplifier.dart';

class VWSimplifier {
  static Geometry? simplify(Geometry geom, double distanceTolerance) {
    VWSimplifier simp = VWSimplifier(geom);
    simp.setDistanceTolerance(distanceTolerance);
    return simp.getResultGeometry();
  }

  Geometry inputGeom;

  double distanceTolerance = 0;

  bool isEnsureValidTopology = true;

  VWSimplifier(this.inputGeom);

  void setDistanceTolerance(double distanceTolerance) {
    if (distanceTolerance < 0.0) {
      throw ("Tolerance must be non-negative");
    }
    this.distanceTolerance = distanceTolerance;
  }

  void setEnsureValid(bool isEnsureValidTopology) {
    this.isEnsureValidTopology = isEnsureValidTopology;
  }

  Geometry? getResultGeometry() {
    if (inputGeom.isEmpty()) {
      return inputGeom.copy();
    }
    return VWTransformer(isEnsureValidTopology, distanceTolerance).transform(inputGeom);
  }
}

class VWTransformer extends GeometryTransformer {
  bool isEnsureValidTopology = true;

  double distanceTolerance;

  VWTransformer(this.isEnsureValidTopology, this.distanceTolerance);

  @override
  CoordinateSequence transformCoordinates(CoordinateSequence coords, Geometry? parent) {
    Array<Coordinate> inputPts = coords.toCoordinateArray();
    Array<Coordinate> newPts;
    if (inputPts.isEmpty) {
      newPts = Array(0);
    } else {
      newPts = VWLineSimplifier.simplify2(inputPts, distanceTolerance);
    }
    return factory.coordinateSequenceFactory.create(newPts);
  }

  @override
  Geometry? transformPolygon(Polygon geom, Geometry? parent) {
    if (geom.isEmpty()) return null;

    Geometry? rawGeom = super.transformPolygon(geom, parent);
    if (parent is MultiPolygon) {
      return rawGeom;
    }
    return createValidArea(rawGeom!);
  }

  @override
  Geometry? transformLinearRing(LinearRing geom, Geometry? parent) {
    bool removeDegenerateRings = parent is Polygon;
    Geometry? simpResult = super.transformLinearRing(geom, parent);
    if (removeDegenerateRings && (simpResult is! LinearRing)) return null;

    return simpResult;
  }

  @override
  Geometry transformMultiPolygon(MultiPolygon geom, Geometry? parent) {
    Geometry rawGeom = super.transformMultiPolygon(geom, parent);
    return createValidArea(rawGeom);
  }

  Geometry createValidArea(Geometry rawAreaGeom) {
    if (isEnsureValidTopology && (!rawAreaGeom.isValid())) {
      return rawAreaGeom.buffer(0.0);
    }

    return rawAreaGeom;
  }
}
