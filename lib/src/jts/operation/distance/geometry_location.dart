import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';

class GeometryLocation {
  static const int kInsideArea = -1;
  Geometry? _component;
  int _segIndex;
  Coordinate pt;

  GeometryLocation(this._component, this._segIndex, this.pt);

  GeometryLocation.of(Geometry component, Coordinate pt) : this(component, kInsideArea, pt);

  Geometry? getGeometryComponent() {
    return _component;
  }

  int getSegmentIndex() {
    return _segIndex;
  }

  Coordinate getCoordinate() {
    return pt;
  }

  bool isInsideArea() {
    return _segIndex == kInsideArea;
  }
}
