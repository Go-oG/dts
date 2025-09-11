import 'dart:math';

import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/util/assert.dart';

import '../overlay/overlay_op.dart';
import 'input_geometry.dart';
import 'overlay_edge.dart';
import 'overlay_graph.dart';
import 'robust_clip_envelope_computer.dart';

final class OverlayUtil {
  static const double _kSafeEnvBufferFactor = 0.1;
  static const int _kSafeEnvGridFactor = 3;
  static const double _kAreaHeuristicTolerance = 0.1;

  static bool isdoubleing(PrecisionModel? pm) {
    if (pm == null) {
      return true;
    }

    return pm.isdoubleing();
  }

  static Envelope? clippingEnvelope(
      OverlayOpCode opCode, InputGeometry inputGeom, PrecisionModel? pm) {
    Envelope? resultEnv = resultEnvelope(opCode, inputGeom, pm);
    if (resultEnv == null) {
      return null;
    }

    Envelope clipEnv = RobustClipEnvelopeComputer.getEnvelopeS(
      inputGeom.getGeometry(0)!,
      inputGeom.getGeometry(1)!,
      resultEnv,
    );
    return safeEnv(clipEnv, pm);
  }

  static Envelope? resultEnvelope(
      OverlayOpCode opCode, InputGeometry inputGeom, PrecisionModel? pm) {
    Envelope? overlapEnv;
    switch (opCode) {
      case OverlayOpCode.intersection:
        Envelope envA = safeEnv(inputGeom.getEnvelope(0), pm);
        Envelope envB = safeEnv(inputGeom.getEnvelope(1), pm);
        overlapEnv = envA.intersection(envB);
        break;
      case OverlayOpCode.difference:
        overlapEnv = safeEnv(inputGeom.getEnvelope(0), pm);
        break;
      default:
        break;
    }
    return overlapEnv;
  }

  static Envelope safeEnv(Envelope env, PrecisionModel? pm) {
    double envExpandDist = safeExpandDistance(env, pm);
    Envelope safeEnv = env.copy();
    safeEnv.expandBy(envExpandDist);
    return safeEnv;
  }

  static double safeExpandDistance(Envelope env, PrecisionModel? pm) {
    double envExpandDist;
    if (isdoubleing(pm)) {
      double minSize = env.shortSide;
      if (minSize <= 0.0) {
        minSize = env.longSide;
      }
      envExpandDist = _kSafeEnvBufferFactor * minSize;
    } else {
      double gridSize = 1.0 / pm!.getScale();
      envExpandDist = _kSafeEnvGridFactor * gridSize;
    }
    return envExpandDist;
  }

  static bool isEmptyResult(
      OverlayOpCode opCode, Geometry? a, Geometry? b, PrecisionModel? pm) {
    switch (opCode) {
      case OverlayOpCode.intersection:
        if (isEnvDisjoint(a, b, pm)) {
          return true;
        }
        break;
      case OverlayOpCode.difference:
        if (isEmpty(a)) {
          return true;
        }
        break;
      case OverlayOpCode.union:
      case OverlayOpCode.symDifference:
        if (isEmpty(a) && isEmpty(b)) {
          return true;
        }
        break;
    }
    return false;
  }

  static bool isEmpty(Geometry? geom) {
    return (geom == null) || geom.isEmpty();
  }

  static bool isEnvDisjoint(Geometry? a, Geometry? b, PrecisionModel? pm) {
    if (isEmpty(a) || isEmpty(b)) {
      return true;
    }

    if (isdoubleing(pm)) {
      return a!.getEnvelopeInternal().disjoint(b!.getEnvelopeInternal());
    }
    return isDisjoint(a!.getEnvelopeInternal(), b!.getEnvelopeInternal(), pm!);
  }

  static bool isDisjoint(Envelope envA, Envelope envB, PrecisionModel pm) {
    if (pm.makePrecise2(envB.minX) > pm.makePrecise2(envA.maxX)) {
      return true;
    }

    if (pm.makePrecise2(envB.maxX) < pm.makePrecise2(envA.minX)) {
      return true;
    }

    if (pm.makePrecise2(envB.minY) > pm.makePrecise2(envA.maxY)) {
      return true;
    }

    if (pm.makePrecise2(envB.maxY) < pm.makePrecise2(envA.minY)) {
      return true;
    }

    return false;
  }

  static Geometry createEmptyResult(int dim, GeometryFactory geomFact) {
    Geometry? result;
    switch (dim) {
      case 0:
        result = geomFact.createPoint();
        break;
      case 1:
        result = geomFact.createLineString();
        break;
      case 2:
        result = geomFact.createPolygon();
        break;
      case -1:
        result = geomFact.createGeomCollection();
        break;
      default:
        Assert.shouldNeverReachHere(
            "Unable to determine overlay result geometry dimension");
    }
    return result!;
  }

  static int resultDimension(OverlayOpCode opCode, int dim0, int dim1) {
    int resultDimension = -1;
    switch (opCode) {
      case OverlayOpCode.intersection:
        resultDimension = min(dim0, dim1).toInt();
        break;
      case OverlayOpCode.union:
        resultDimension = max(dim0, dim1).toInt();
        break;
      case OverlayOpCode.difference:
        resultDimension = dim0;
        break;
      case OverlayOpCode.symDifference:
        resultDimension = max(dim0, dim1).toInt();
        break;
    }
    return resultDimension;
  }

  static Geometry createResultGeometry(
    List<Polygon>? resultPolyList,
    List<LineString>? resultLineList,
    List<Point>? resultPointList,
    GeometryFactory geometryFactory,
  ) {
    List<Geometry> geomList = [];
    if (resultPolyList != null) {
      geomList.addAll(resultPolyList);
    }

    if (resultLineList != null) {
      geomList.addAll(resultLineList);
    }

    if (resultPointList != null) {
      geomList.addAll(resultPointList);
    }

    return geometryFactory.buildGeometry(geomList);
  }

  static Geometry toLines(
      OverlayGraph graph, bool isOutputEdges, GeometryFactory geomFact) {
    List<LineString> lines = [];
    for (OverlayEdge edge in graph.getEdges()) {
      bool includeEdge = isOutputEdges || edge.isInResultArea();
      if (!includeEdge) {
        continue;
      }

      List<Coordinate> pts = edge.getCoordinatesOriented();
      LineString line = geomFact.createLineString2(pts);
      line.userData = labelForResult(edge);
      lines.add(line);
    }
    return geomFact.buildGeometry(lines);
  }

  static String labelForResult(OverlayEdge edge) {
    return edge.getLabel().toString2(edge.isForward()) +
        (edge.isInResultArea() ? " Res" : "");
  }

  static Coordinate? round2(Point pt, PrecisionModel? pm) {
    if (pt.isEmpty()) {
      return null;
    }

    return round(pt.getCoordinate()!, pm);
  }

  static Coordinate round(Coordinate p, PrecisionModel? pm) {
    if (!isdoubleing(pm)) {
      Coordinate pRound = p.copy();
      pm!.makePrecise(pRound);
      return pRound;
    }
    return p;
  }

  static bool isResultAreaConsistent(
      Geometry? geom0, Geometry? geom1, OverlayOpCode opCode, Geometry result) {
    if ((geom0 == null) || (geom1 == null)) {
      return true;
    }

    if (result.getDimension() < 2) {
      return true;
    }

    double areaResult = result.getArea();
    double areaA = geom0.getArea();
    double areaB = geom1.getArea();
    bool isConsistent = true;
    switch (opCode) {
      case OverlayOpCode.intersection:
        isConsistent = isLess(areaResult, areaA, _kAreaHeuristicTolerance) &&
            isLess(areaResult, areaB, _kAreaHeuristicTolerance);
        break;
      case OverlayOpCode.difference:
        isConsistent = isDifferenceAreaConsistent(
            areaA, areaB, areaResult, _kAreaHeuristicTolerance);
        break;
      case OverlayOpCode.symDifference:
        isConsistent =
            isLess(areaResult, areaA + areaB, _kAreaHeuristicTolerance);
        break;
      case OverlayOpCode.union:
        isConsistent = (isLess(areaA, areaResult, _kAreaHeuristicTolerance) &&
                isLess(areaB, areaResult, _kAreaHeuristicTolerance)) &&
            isGreater(areaResult, areaA - areaB, _kAreaHeuristicTolerance);
        break;
    }
    return isConsistent;
  }

  static bool isDifferenceAreaConsistent(
      double areaA, double areaB, double areaResult, double tolFrac) {
    if (!isLess(areaResult, areaA, tolFrac)) {
      return false;
    }

    double areaDiffMin = (areaA - areaB) - (tolFrac * areaA);
    return areaResult > areaDiffMin;
  }

  static bool isLess(double v1, double v2, double tol) {
    return v1 <= (v2 * (1 + tol));
  }

  static bool isGreater(double v1, double v2, double tol) {
    return v1 >= (v2 * (1 - tol));
  }
}
