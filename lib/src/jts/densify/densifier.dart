 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/util/geometry_transformer.dart';

final class Densifier {
  static Geometry? densify(Geometry geom, double distanceTolerance) {
    final densifier = Densifier(geom);
    densifier.setDistanceTolerance(distanceTolerance);
    return densifier.getResultGeometry();
  }

  static Array<Coordinate> _densifyPoints(Array<Coordinate> pts, double distanceTolerance, PrecisionModel precModel) {
    LineSegment seg = LineSegment.empty();
    CoordinateList coordList = CoordinateList();
    for (int i = 0; i < (pts.length - 1); i++) {
      seg.p0 = pts[i];
      seg.p1 = pts[i + 1];
      coordList.add3(seg.p0, false);
      double len = seg.getLength();
      if (len <= distanceTolerance) {
        continue;
      }

      int densifiedSegCount = (Math.ceil(len / distanceTolerance));
      double densifiedSegLen = len / densifiedSegCount;
      for (int j = 1; j < densifiedSegCount; j++) {
        double segFract = (j * densifiedSegLen) / len;
        Coordinate p = seg.pointAlong(segFract);
        if ((!Double.isNaN(seg.p0.z)) && (!Double.isNaN(seg.p1.z))) {
          p.setZ(seg.p0.z + (segFract * (seg.p1.z - seg.p0.z)));
        }
        precModel.makePrecise(p);
        coordList.add3(p, false);
      }
    }
    if (pts.length > 0) {
      coordList.add3(pts[pts.length - 1], false);
    }

    return coordList.toCoordinateArray();
  }

  Geometry inputGeom;

  double _distanceTolerance = 0.0;

  bool _isValidated = true;

  Densifier(this.inputGeom);

  void setDistanceTolerance(double distanceTolerance) {
    if (distanceTolerance <= 0.0) {
      throw IllegalArgumentException("Tolerance must be positive");
    }

    _distanceTolerance = distanceTolerance;
  }

  void setValidate(bool isValidated) {
    _isValidated = isValidated;
  }

  Geometry? getResultGeometry() {
    return DensifyTransformer(_distanceTolerance, _isValidated).transform(inputGeom);
  }
}

class DensifyTransformer extends GeometryTransformer {
  double distanceTolerance;

  bool isValidated;

  DensifyTransformer(this.distanceTolerance, this.isValidated);

  @override
  CoordinateSequence transformCoordinates(CoordinateSequence coords, Geometry? parent) {
    Array<Coordinate> inputPts = coords.toCoordinateArray();
    Array<Coordinate> newPts = Densifier._densifyPoints(inputPts, distanceTolerance, parent!.getPrecisionModel());
    if ((parent is LineString) && (newPts.length == 1)) {
      newPts = Array<Coordinate>(0);
    }
    return factory.coordinateSequenceFactory.create(newPts);
  }

  @override
  Geometry transformPolygon(Polygon geom, Geometry? parent) {
    Geometry? roughGeom = super.transformPolygon(geom, parent);
    if (parent is MultiPolygon) {
      return roughGeom!;
    }
    return createValidArea(roughGeom!);
  }

  @override
  Geometry transformMultiPolygon(MultiPolygon geom, Geometry? parent) {
    Geometry roughGeom = super.transformMultiPolygon(geom, parent);
    return createValidArea(roughGeom);
  }

  Geometry createValidArea(Geometry roughAreaGeom) {
    if ((!isValidated) || roughAreaGeom.isValid()) {
      return roughAreaGeom;
    }

    return roughAreaGeom.buffer(0.0);
  }
}
