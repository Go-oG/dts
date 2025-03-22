 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/util/geometry_transformer.dart';

import 'douglas_peucker_line_simplifier.dart';

class DouglasPeuckerSimplifier {
  static Geometry simplify(Geometry geom, double distanceTolerance) {
    DouglasPeuckerSimplifier tss = DouglasPeuckerSimplifier(geom);
    tss.setDistanceTolerance(distanceTolerance);
    return tss.getResultGeometry()!;
  }

  Geometry inputGeom;

  double distanceTolerance = 0;

  bool _isEnsureValidTopology = true;

  DouglasPeuckerSimplifier(this.inputGeom);

  void setDistanceTolerance(double distanceTolerance) {
    if (distanceTolerance < 0.0) {
      throw ("Tolerance must be non-negative");
    }
    this.distanceTolerance = distanceTolerance;
  }

  void setEnsureValid(bool isEnsureValidTopology) {
    _isEnsureValidTopology = isEnsureValidTopology;
  }

  Geometry? getResultGeometry() {
    if (inputGeom.isEmpty()) {
      return inputGeom.copy();
    }
    return DPTransformer(_isEnsureValidTopology, distanceTolerance).transform(inputGeom);
  }
}

class DPTransformer extends GeometryTransformer {
  bool isEnsureValidTopology = true;

  double distanceTolerance;

  DPTransformer(this.isEnsureValidTopology, this.distanceTolerance);

  @override
  CoordinateSequence transformCoordinates(CoordinateSequence coords, Geometry? parent) {
    bool isPreserveEndpoint = parent is! LinearRing;
    Array<Coordinate> inputPts = coords.toCoordinateArray();
    Array<Coordinate> newPts;
    if (inputPts.isEmpty) {
      newPts = Array(0);
    } else {
      newPts = DouglasPeuckerLineSimplifier.simplify2(inputPts, distanceTolerance, isPreserveEndpoint);
    }
    return factory.coordinateSequenceFactory.create(newPts);
  }

  @override
  Geometry? transformPolygon(Polygon geom, Geometry? parent) {
    if (geom.isEmpty()) {
      return null;
    }

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
    if (removeDegenerateRings && (simpResult is! LinearRing)) {
      return null;
    }

    return simpResult;
  }

  @override
  Geometry transformMultiPolygon(MultiPolygon geom, Geometry? parent) {
    Geometry rawGeom = super.transformMultiPolygon(geom, parent);
    return createValidArea(rawGeom);
  }

  Geometry createValidArea(Geometry rawAreaGeom) {
    bool isValidArea = (rawAreaGeom.getDimension() == 2) && rawAreaGeom.isValid();
    if (isEnsureValidTopology && (!isValidArea)) {
      return rawAreaGeom.buffer(0.0);
    }
    return rawAreaGeom;
  }
}
