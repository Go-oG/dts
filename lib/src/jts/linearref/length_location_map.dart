import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry.dart';

import 'linear_iterator.dart';
import 'linear_location.dart';

class LengthLocationMap {
  static LinearLocation getLocation3(Geometry linearGeom, double length) {
    LengthLocationMap locater = LengthLocationMap(linearGeom);
    return locater.getLocation(length);
  }

  static LinearLocation getLocation4(
      Geometry linearGeom, double length, bool resolveLower) {
    LengthLocationMap locater = LengthLocationMap(linearGeom);
    return locater.getLocation2(length, resolveLower);
  }

  static double getLength2(Geometry linearGeom, LinearLocation loc) {
    LengthLocationMap locater = LengthLocationMap(linearGeom);
    return locater.getLength(loc);
  }

  final Geometry _linearGeom;

  LengthLocationMap(this._linearGeom);

  LinearLocation getLocation(double length) {
    return getLocation2(length, true);
  }

  LinearLocation getLocation2(double length, bool resolveLower) {
    double forwardLength = length;
    if (length < 0.0) {
      double lineLen = _linearGeom.getLength();
      forwardLength = lineLen + length;
    }
    LinearLocation loc = getLocationForward(forwardLength);
    if (resolveLower) {
      return loc;
    }
    return resolveHigher(loc);
  }

  LinearLocation getLocationForward(double length) {
    if (length <= 0.0) {
      return LinearLocation.empty();
    }

    double totalLength = 0.0;
    LinearIterator it = LinearIterator.of(_linearGeom);
    while (it.hasNext()) {
      if (it.isEndOfLine()) {
        if (totalLength == length) {
          int compIndex = it.getComponentIndex();
          int segIndex = it.getVertexIndex();
          return LinearLocation(compIndex, segIndex, 0.0);
        }
      } else {
        Coordinate p0 = it.getSegmentStart();
        Coordinate p1 = it.getSegmentEnd()!;
        double segLen = p1.distance(p0);
        if ((totalLength + segLen) > length) {
          double frac = (length - totalLength) / segLen;
          int compIndex = it.getComponentIndex();
          int segIndex = it.getVertexIndex();
          return LinearLocation(compIndex, segIndex, frac);
        }
        totalLength += segLen;
      }
      it.next();
    }
    return LinearLocation.getEndLocation(_linearGeom);
  }

  LinearLocation resolveHigher(LinearLocation loc) {
    if (!loc.isEndpoint(_linearGeom)) {
      return loc;
    }

    int compIndex = loc.getComponentIndex();
    if (compIndex >= (_linearGeom.getNumGeometries() - 1)) {
      return loc;
    }

    do {
      compIndex++;
    } while ((compIndex < (_linearGeom.getNumGeometries() - 1)) &&
        (_linearGeom.getGeometryN(compIndex).getLength() == 0));
    return LinearLocation(compIndex, 0, 0.0);
  }

  double getLength(LinearLocation loc) {
    double totalLength = 0.0;
    LinearIterator it = LinearIterator.of(_linearGeom);
    while (it.hasNext()) {
      if (!it.isEndOfLine()) {
        Coordinate p0 = it.getSegmentStart();
        Coordinate p1 = it.getSegmentEnd()!;
        double segLen = p1.distance(p0);
        if ((loc.getComponentIndex() == it.getComponentIndex()) &&
            (loc.getSegmentIndex() == it.getVertexIndex())) {
          return totalLength + (segLen * loc.getSegmentFraction());
        }
        totalLength += segLen;
      } else if (loc.getComponentIndex() == it.getComponentIndex()) {
        return totalLength;
      }
      it.next();
    }
    return totalLength;
  }
}
