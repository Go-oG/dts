import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_segment.dart';
import 'package:dts/src/jts/geom/line_string.dart';

class LinearLocation implements Comparable<LinearLocation> {
  static LinearLocation getEndLocation(Geometry linear) {
    LinearLocation loc = LinearLocation.empty();
    loc.setToEnd(linear);
    return loc;
  }

  static Coordinate pointAlongSegmentByFraction(
      Coordinate p0, Coordinate p1, double frac) {
    if (frac <= 0.0) return p0;

    if (frac >= 1.0) return p1;

    double x = ((p1.x - p0.x) * frac) + p0.x;
    double y = ((p1.y - p0.y) * frac) + p0.y;
    double z = ((p1.z - p0.z) * frac) + p0.z;
    return Coordinate(x, y, z);
  }

  int componentIndex = 0;

  int _segmentIndex = 0;

  double _segmentFraction = 0.0;

  LinearLocation(
      this.componentIndex, this._segmentIndex, this._segmentFraction) {
    normalize();
  }

  LinearLocation.empty();

  LinearLocation.of(int segmentIndex, double segmentFraction)
      : this(0, segmentIndex, segmentFraction);

  LinearLocation.of2(this.componentIndex, this._segmentIndex,
      this._segmentFraction, bool doNormalize) {
    if (doNormalize) normalize();
  }

  LinearLocation.of3(LinearLocation loc) {
    componentIndex = loc.componentIndex;
    _segmentIndex = loc._segmentIndex;
    _segmentFraction = loc._segmentFraction;
  }

  void normalize() {
    if (_segmentFraction < 0.0) {
      _segmentFraction = 0.0;
    }
    if (_segmentFraction > 1.0) {
      _segmentFraction = 1.0;
    }
    if (componentIndex < 0) {
      componentIndex = 0;
      _segmentIndex = 0;
      _segmentFraction = 0.0;
    }
    if (_segmentIndex < 0) {
      _segmentIndex = 0;
      _segmentFraction = 0.0;
    }
    if (_segmentFraction == 1.0) {
      _segmentFraction = 0.0;
      _segmentIndex += 1;
    }
  }

  void clamp(Geometry linear) {
    if (componentIndex >= linear.getNumGeometries()) {
      setToEnd(linear);
      return;
    }
    if (_segmentIndex >= linear.getNumPoints()) {
      LineString line = (linear.getGeometryN(componentIndex) as LineString);
      _segmentIndex = numSegments(line);
      _segmentFraction = 1.0;
    }
  }

  void snapToVertex(Geometry linearGeom, double minDistance) {
    if ((_segmentFraction <= 0.0) || (_segmentFraction >= 1.0)) return;

    double segLen = getSegmentLength(linearGeom);
    double lenToStart = _segmentFraction * segLen;
    double lenToEnd = segLen - lenToStart;
    if ((lenToStart <= lenToEnd) && (lenToStart < minDistance)) {
      _segmentFraction = 0.0;
    } else if ((lenToEnd <= lenToStart) && (lenToEnd < minDistance)) {
      _segmentFraction = 1.0;
    }
  }

  double getSegmentLength(Geometry linearGeom) {
    LineString lineComp =
        (linearGeom.getGeometryN(componentIndex) as LineString);
    int segIndex = _segmentIndex;
    if (_segmentIndex >= numSegments(lineComp)) {
      segIndex = lineComp.getNumPoints() - 2;
    }

    Coordinate p0 = lineComp.getCoordinateN(segIndex);
    Coordinate p1 = lineComp.getCoordinateN(segIndex + 1);
    return p0.distance(p1);
  }

  void setToEnd(Geometry linear) {
    componentIndex = linear.getNumGeometries() - 1;
    LineString lastLine = (linear.getGeometryN(componentIndex) as LineString);
    _segmentIndex = numSegments(lastLine);
    _segmentFraction = 0.0;
  }

  int getComponentIndex() {
    return componentIndex;
  }

  int getSegmentIndex() {
    return _segmentIndex;
  }

  double getSegmentFraction() {
    return _segmentFraction;
  }

  bool isVertex() {
    return (_segmentFraction <= 0.0) || (_segmentFraction >= 1.0);
  }

  Coordinate getCoordinate(Geometry linearGeom) {
    LineString lineComp =
        ((linearGeom.getGeometryN(componentIndex) as LineString));
    Coordinate p0 = lineComp.getCoordinateN(_segmentIndex);
    if (_segmentIndex >= numSegments(lineComp)) return p0;

    Coordinate p1 = lineComp.getCoordinateN(_segmentIndex + 1);
    return pointAlongSegmentByFraction(p0, p1, _segmentFraction);
  }

  LineSegment getSegment(Geometry linearGeom) {
    LineString lineComp =
        ((linearGeom.getGeometryN(componentIndex) as LineString));
    Coordinate p0 = lineComp.getCoordinateN(_segmentIndex);
    if (_segmentIndex >= numSegments(lineComp)) {
      Coordinate prev = lineComp.getCoordinateN(lineComp.getNumPoints() - 2);
      return LineSegment(prev, p0);
    }
    Coordinate p1 = lineComp.getCoordinateN(_segmentIndex + 1);
    return LineSegment(p0, p1);
  }

  bool isValid(Geometry linearGeom) {
    if ((componentIndex < 0) ||
        (componentIndex >= linearGeom.getNumGeometries())) {
      return false;
    }

    LineString lineComp =
        ((linearGeom.getGeometryN(componentIndex) as LineString));
    if ((_segmentIndex < 0) || (_segmentIndex > lineComp.getNumPoints())) {
      return false;
    }

    if ((_segmentIndex == lineComp.getNumPoints()) && (_segmentFraction != 0.0)) {
      return false;
    }

    if ((_segmentFraction < 0.0) || (_segmentFraction > 1.0)) return false;

    return true;
  }

  @override
  int compareTo(LinearLocation other) {
    if (componentIndex < other.componentIndex) return -1;

    if (componentIndex > other.componentIndex) return 1;

    if (_segmentIndex < other._segmentIndex) return -1;

    if (_segmentIndex > other._segmentIndex) return 1;

    if (_segmentFraction < other._segmentFraction) return -1;

    if (_segmentFraction > other._segmentFraction) return 1;

    return 0;
  }

  int compareLocationValues(
      int componentIndex1, int segmentIndex1, double segmentFraction1) {
    if (componentIndex < componentIndex1) return -1;

    if (componentIndex > componentIndex1) return 1;

    if (_segmentIndex < segmentIndex1) return -1;

    if (_segmentIndex > segmentIndex1) return 1;

    if (_segmentFraction < segmentFraction1) return -1;

    if (_segmentFraction > segmentFraction1) return 1;

    return 0;
  }

  static int compareLocationValues2(
    int componentIndex0,
    int segmentIndex0,
    double segmentFraction0,
    int componentIndex1,
    int segmentIndex1,
    double segmentFraction1,
  ) {
    if (componentIndex0 < componentIndex1) return -1;

    if (componentIndex0 > componentIndex1) return 1;

    if (segmentIndex0 < segmentIndex1) return -1;

    if (segmentIndex0 > segmentIndex1) return 1;

    if (segmentFraction0 < segmentFraction1) return -1;

    if (segmentFraction0 > segmentFraction1) return 1;

    return 0;
  }

  bool isOnSameSegment(LinearLocation loc) {
    if (componentIndex != loc.componentIndex) return false;

    if (_segmentIndex == loc._segmentIndex) return true;

    if (((loc._segmentIndex - _segmentIndex) == 1) &&
        (loc._segmentFraction == 0.0)) {
      return true;
    }

    if (((_segmentIndex - loc._segmentIndex) == 1) && (_segmentFraction == 0.0)) {
      return true;
    }

    return false;
  }

  bool isEndpoint(Geometry linearGeom) {
    LineString lineComp =
        ((linearGeom.getGeometryN(componentIndex) as LineString));
    int nseg = numSegments(lineComp);
    return (_segmentIndex >= nseg) ||
        ((_segmentIndex == (nseg - 1)) && (_segmentFraction >= 1.0));
  }

  LinearLocation toLowest(Geometry linearGeom) {
    LineString lineComp =
        ((linearGeom.getGeometryN(componentIndex) as LineString));
    int nseg = numSegments(lineComp);
    if (_segmentIndex < nseg) return this;

    return LinearLocation.of2(componentIndex, nseg - 1, 1.0, false);
  }

  Object clone() {
    return copy();
  }

  LinearLocation copy() {
    return LinearLocation(componentIndex, _segmentIndex, _segmentFraction);
  }

  static int numSegments(LineString line) {
    int npts = line.getNumPoints();
    if (npts <= 1) return 0;

    return npts - 1;
  }
}
