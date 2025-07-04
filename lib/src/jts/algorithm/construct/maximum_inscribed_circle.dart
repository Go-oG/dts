import 'dart:math';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/multi_polygon.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/operation/distance/indexed_facet_distance.dart';

class MaximumInscribedCircle with InitMixin {
  static Point getCenterS(Geometry polygonal, double tolerance) {
    return MaximumInscribedCircle(polygonal, tolerance).getCenter();
  }

  static LineString getRadiusLineS(Geometry polygonal, double tolerance) {
    return MaximumInscribedCircle(polygonal, tolerance).getRadiusLine();
  }

  static int computeMaximumIterations(Geometry geom, double toleranceDist) {
    double diam = geom.getEnvelopeInternal().diameter;
    double ncells = diam / toleranceDist;
    int factor = log(ncells).toInt();
    if (factor < 1) {
      factor = 1;
    }
    return 2000 + (2000 * factor);
  }

  final Geometry _inputGeom;

  late final GeometryFactory factory;
  late final IndexedPointInAreaLocator _ptLocater;
  late final IndexedFacetDistance _indexedDistance;

  double tolerance;

  late _Cell _centerCell;

  late Coordinate _centerPt;

  late Coordinate radiusPt;

  late Point _centerPoint;

  late Point _radiusPoint;

  MaximumInscribedCircle(this._inputGeom, this.tolerance) {
    final polygonal = _inputGeom;
    factory = polygonal.factory;
    _ptLocater = IndexedPointInAreaLocator(polygonal);
    _indexedDistance = IndexedFacetDistance(polygonal.getBoundary()!);

    if (tolerance <= 0) {
      throw ("Tolerance must be positive");
    }
    if (!((polygonal is Polygon) || (polygonal is MultiPolygon))) {
      throw ("Input geometry must be a Polygon or MultiPolygon");
    }
    if (polygonal.isEmpty()) {
      throw ("Empty input geometry is not supported");
    }
  }

  Point getCenter() {
    _compute();
    return _centerPoint;
  }

  Point getRadiusPoint() {
    _compute();
    return _radiusPoint;
  }

  LineString getRadiusLine() {
    _compute();
    return factory.createLineString2([_centerPt.copy(), radiusPt.copy()].toArray());
  }

  double _distanceToBoundary(Point p) {
    double dist = _indexedDistance.distance(p);
    bool isOutide = Location.exterior == _ptLocater.locate(p.getCoordinate()!);
    if (isOutide) {
      return -dist;
    }
    return dist;
  }

  double _distanceToBoundary2(double x, double y) {
    Coordinate coord = Coordinate(x, y);
    Point pt = factory.createPoint2(coord);
    return _distanceToBoundary(pt);
  }

  void _compute() {
    if (getAndMarkInit()) {
      return;
    }
    PriorityQueue<_Cell> cellQueue = PriorityQueue();
    _createInitialGrid(_inputGeom.getEnvelopeInternal(), cellQueue);
    _Cell farthestCell = _createInterorPointCell(_inputGeom);
    int maxIter = computeMaximumIterations(_inputGeom, tolerance);
    int iter = 0;
    while ((cellQueue.isNotEmpty) && (iter < maxIter)) {
      iter++;
      final cell = cellQueue.removeFirst();
      if (cell.maxDistance < farthestCell.distance) {
        break;
      }

      if (cell.distance > farthestCell.distance) {
        farthestCell = cell;
      }
      double potentialIncrease = cell.maxDistance - farthestCell.distance;
      if (potentialIncrease > tolerance) {
        double h2 = cell.hSide / 2;
        cellQueue.add(_createCell(cell.x - h2, cell.y - h2, h2));
        cellQueue.add(_createCell(cell.x + h2, cell.y - h2, h2));
        cellQueue.add(_createCell(cell.x - h2, cell.y + h2, h2));
        cellQueue.add(_createCell(cell.x + h2, cell.y + h2, h2));
      }
    }
    _centerCell = farthestCell;
    _centerPt = Coordinate(_centerCell.x, _centerCell.y);
    _centerPoint = factory.createPoint2(_centerPt);
    Array<Coordinate> nearestPts = _indexedDistance.nearestPoints(_centerPoint)!;
    radiusPt = nearestPts[0].copy();
    _radiusPoint = factory.createPoint2(radiusPt);
  }

  void _createInitialGrid(Envelope env, PriorityQueue<_Cell> cellQueue) {
    double cellSize = env.longSide;

    double hSide = cellSize / 2.0;
    if (cellSize == 0) {
      return;
    }

    Coordinate centre = env.centre()!;
    cellQueue.add(_createCell(centre.x, centre.y, hSide));
  }

  _Cell _createCell(double x, double y, double hSide) {
    return _Cell(x, y, hSide, _distanceToBoundary2(x, y));
  }

  _Cell _createInterorPointCell(Geometry geom) {
    Point p = geom.getInteriorPoint();
    return _Cell(p.getX(), p.getY(), 0, _distanceToBoundary(p));
  }
}

class _Cell implements Comparable<_Cell> {
  static const double _sqrt2 = 1.4142135623730951;

  final double x;

  final double y;

  final double hSide;

  final double distance;

  late final double maxDistance;

  _Cell(this.x, this.y, this.hSide, this.distance) {
    maxDistance = distance + (hSide * _sqrt2);
  }

  Envelope getEnvelope() {
    return Envelope.fromLTRB(x - hSide, y - hSide, x + hSide, y + hSide);
  }

  @override
  int compareTo(_Cell o) {
    return -maxDistance.compareTo(o.maxDistance);
  }
}
