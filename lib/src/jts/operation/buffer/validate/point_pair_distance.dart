import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

class OpPointPairDistance {
  final Array<Coordinate> _pt = [Coordinate(), Coordinate()].toArray();

  double distance = double.nan;

  bool isNull = true;

  void initialize() {
    isNull = true;
  }

  void initialize2(Coordinate p0, Coordinate p1) {
    _pt[0].setCoordinate(p0);
    _pt[1].setCoordinate(p1);
    distance = p0.distance(p1);
    isNull = false;
  }

  void initialize3(Coordinate p0, Coordinate p1, double distance) {
    _pt[0].setCoordinate(p0);
    _pt[1].setCoordinate(p1);
    this.distance = distance;
    isNull = false;
  }

  double getDistance() {
    return distance;
  }

  Array<Coordinate> getCoordinates() {
    return _pt;
  }

  Coordinate getCoordinate(int i) {
    return _pt[i];
  }

  void setMaximum(OpPointPairDistance ptDist) {
    setMaximum2(ptDist._pt[0], ptDist._pt[1]);
  }

  void setMaximum2(Coordinate p0, Coordinate p1) {
    if (isNull) {
      initialize2(p0, p1);
      return;
    }
    double dist = p0.distance(p1);
    if (dist > distance) {
      initialize3(p0, p1, dist);
    }
  }

  void setMinimum(OpPointPairDistance ptDist) {
    setMinimum2(ptDist._pt[0], ptDist._pt[1]);
  }

  void setMinimum2(Coordinate p0, Coordinate p1) {
    if (isNull) {
      initialize2(p0, p1);
      return;
    }
    double dist = p0.distance(p1);
    if (dist < distance) {
      initialize3(p0, p1, dist);
    }
  }
}
