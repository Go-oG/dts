import 'package:dts/src/jts/geom/coordinate.dart';

class PointPairDistance {
  final List<Coordinate> _pt = [Coordinate(), Coordinate()];

  double _distance = double.nan;

  bool _isNull = true;

  void initialize() {
    _isNull = true;
  }

  void initialize2(Coordinate p0, Coordinate p1) {
    initialize3(p0, p1, p0.distance(p1));
  }

  void initialize3(Coordinate p0, Coordinate p1, double distance) {
    _pt[0].setCoordinate(p0);
    _pt[1].setCoordinate(p1);
    _distance = distance;
    _isNull = false;
  }

  double getDistance() {
    return _distance;
  }

  List<Coordinate> getCoordinates() => _pt;

  Coordinate getCoordinate(int i) {
    return _pt[i];
  }

  void setMaximum(PointPairDistance ptDist) {
    setMaximum2(ptDist._pt[0], ptDist._pt[1]);
  }

  void setMaximum2(Coordinate p0, Coordinate p1) {
    if (_isNull) {
      initialize2(p0, p1);
      return;
    }
    double dist = p0.distance(p1);
    if (dist > _distance) {
      initialize3(p0, p1, dist);
    }
  }

  void setMinimum(PointPairDistance ptDist) {
    setMinimum2(ptDist._pt[0], ptDist._pt[1]);
  }

  void setMinimum2(Coordinate p0, Coordinate p1) {
    if (_isNull) {
      initialize2(p0, p1);
      return;
    }
    double dist = p0.distance(p1);
    if (dist < _distance) {
      initialize3(p0, p1, dist);
    }
  }
}
