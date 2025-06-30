import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geom.dart';

class GeometryLocation {
  static const int INSIDE_AREA = -1;
  Geometry? _component;
  int _segIndex;
  Coordinate pt;

  GeometryLocation(this._component, this._segIndex, this.pt);

  GeometryLocation.of(Geometry component, Coordinate pt) : this(component, INSIDE_AREA, pt);

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
    return _segIndex == INSIDE_AREA;
  }
}
