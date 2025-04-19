import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/locate/point_on_geometry_locator.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/geom/polygonal.dart';
import 'package:dts/src/jts/operation/distance/indexed_facet_distance.dart';

import 'indexed_distance_to_point.dart';
import 'maximum_inscribed_circle.dart';

class LargestEmptyCircle with InitMixin {
  static Point getCenterS(Geometry obstacles, double tolerance) {
    return getCenterS2(obstacles, null, tolerance);
  }

  static Point getCenterS2(Geometry obstacles, Geometry? boundary, double tolerance) {
    return LargestEmptyCircle(obstacles, boundary, tolerance).getCenter();
  }

  static LineString getRadiusLineS(Geometry obstacles, double tolerance) {
    return getRadiusLineS2(obstacles, null, tolerance);
  }

  static LineString getRadiusLineS2(Geometry obstacles, Geometry? boundary, double tolerance) {
    return LargestEmptyCircle(obstacles, boundary, tolerance).getRadiusLine();
  }

  final Geometry _obstacles;
  late final GeometryFactory _factory;
  late final IndexedDistanceToPoint _obstacleDistance;

  Geometry? _boundary;
  double _tolerance = 0;

  late IndexedPointInAreaLocator _boundaryPtLocater;
  late IndexedFacetDistance _boundaryDistance;

  Envelope? _gridEnv;

  late _Cell _farthestCell;

  late _Cell _centerCell;

  Coordinate? _centerPt;

  Point? _centerPoint;

  Coordinate? _radiusPt;

  Point? _radiusPoint;

  Geometry? _bounds;

  LargestEmptyCircle(this._obstacles, Geometry? boundary, double tolerance) {
    if (_obstacles.isEmpty()) {
      throw ("Obstacles geometry is empty or null");
    }
    if ((boundary != null) && (boundary is! Polygonal)) {
      throw ("Boundary must be polygonal");
    }
    if (tolerance <= 0) {
      throw ("Accuracy tolerance is non-positive: tolerance");
    }

    _boundary = boundary;
    _factory = _obstacles.factory;
    _tolerance = tolerance;
    _obstacleDistance = IndexedDistanceToPoint(_obstacles);
  }

  Point getCenter() {
    _compute();
    return _centerPoint!;
  }

  Point getRadiusPoint() {
    _compute();
    return _radiusPoint!;
  }

  LineString getRadiusLine() {
    _compute();
    LineString radiusLine =
        _factory.createLineString2(Array.list([_centerPt!.copy(), _radiusPt!.copy()]));
    return radiusLine;
  }

  double _distanceToConstraints(Point p) {
    bool isOutide = Location.exterior == _boundaryPtLocater.locate(p.getCoordinate()!);
    if (isOutide) {
      double boundaryDist = _boundaryDistance.distance(p);
      return -boundaryDist;
    }
    double dist = _obstacleDistance.distance(p);
    return dist;
  }

  double _distanceToConstraints2(double x, double y) {
    Coordinate coord = Coordinate(x, y);
    Point pt = _factory.createPoint2(coord);
    return _distanceToConstraints(pt);
  }

  void _initBoundary() {
    _bounds = _boundary;
    if ((_bounds == null) || _bounds!.isEmpty()) {
      _bounds = _obstacles.convexHull();
    }
    _gridEnv = _bounds!.getEnvelopeInternal();
    if (_bounds!.getDimension() >= 2) {
      _boundaryPtLocater = IndexedPointInAreaLocator(_bounds!);
      _boundaryDistance = IndexedFacetDistance(_bounds!);
    }
  }

  void _compute() {
    _initBoundary();
    if (getAndMarkInit()) {
      return;
    }
    PriorityQueue<_Cell> cellQueue = PriorityQueue();
    _createInitialGrid(_gridEnv!, cellQueue);
    _farthestCell = _createCentroidCell(_obstacles);
    int maxIter = MaximumInscribedCircle.computeMaximumIterations(_bounds!, _tolerance);
    int iter = 0;
    while ((cellQueue.isNotEmpty) && (iter < maxIter)) {
      iter++;
      _Cell cell = cellQueue.removeFirst();
      if (cell.distance > _farthestCell.distance) {
        _farthestCell = cell;
      }
      if (_mayContainCircleCenter(cell)) {
        double h2 = cell.hSide / 2;
        cellQueue.add(_createCell(cell.x - h2, cell.y - h2, h2));
        cellQueue.add(_createCell(cell.x + h2, cell.y - h2, h2));
        cellQueue.add(_createCell(cell.x - h2, cell.y + h2, h2));
        cellQueue.add(_createCell(cell.x + h2, cell.y + h2, h2));
      }
    }
    _centerCell = _farthestCell;
    _centerPt = Coordinate(_centerCell.x, _centerCell.y);
    _centerPoint = _factory.createPoint2(_centerPt);
    Array<Coordinate> nearestPts = _obstacleDistance.nearestPoints(_centerPoint!)!;
    _radiusPt = nearestPts[0].copy();
    _radiusPoint = _factory.createPoint2(_radiusPt);
  }

  bool _mayContainCircleCenter(_Cell cell) {
    if (cell.isFullyOutside()) {
      return false;
    }

    if (cell.isOutside()) {
      bool isOverlapSignificant = cell.maxDistance > _tolerance;
      return isOverlapSignificant;
    }
    double potentialIncrease = cell.maxDistance - _farthestCell.maxDistance;
    return potentialIncrease > _tolerance;
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

  _Cell _createCell(double x, double y, double h) {
    return _Cell(x, y, h, _distanceToConstraints2(x, y));
  }

  _Cell _createCentroidCell(Geometry geom) {
    Point p = geom.getCentroid();
    return _Cell(p.getX(), p.getY(), 0, _distanceToConstraints(p));
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

  bool isFullyOutside() {
    return maxDistance < 0;
  }

  bool isOutside() {
    return distance < 0;
  }

  @override
  int compareTo(_Cell o) {
    return -Double.compare(maxDistance, o.maxDistance);
  }
}
