import 'package:dts/src/jts/algorithm/ray_crossing_counter.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/math/math.dart';

import 'axis_plane_coordinate_sequence.dart';

class PlanarPolygon3D {
  late Plane3D _plane;

  Polygon poly;

  int _facingPlane = -1;

  PlanarPolygon3D(this.poly) {
    _plane = findBestFitPlane(poly);
    _facingPlane = _plane.closestAxisPlane();
  }

  Plane3D findBestFitPlane(Polygon poly) {
    CoordinateSequence seq = poly.getExteriorRing().getCoordinateSequence();
    Coordinate basePt = averagePoint(seq);
    Vector3D normal = averageNormal(seq);
    return Plane3D(normal, basePt);
  }

  Vector3D averageNormal(CoordinateSequence seq) {
    int n = seq.size();
    Coordinate sum = Coordinate(0, 0, 0);
    Coordinate p1 = Coordinate(0, 0, 0);
    Coordinate p2 = Coordinate(0, 0, 0);
    for (int i = 0; i < (n - 1); i++) {
      seq.getCoordinate2(i, p1);
      seq.getCoordinate2(i + 1, p2);
      sum.x += (p1.y - p2.y) * (p1.z + p2.z);
      sum.y += (p1.z - p2.z) * (p1.x + p2.x);
      sum.z = (sum.z + ((p1.x - p2.x) * (p1.y + p2.y)));
    }
    sum.x /= n;
    sum.y /= n;
    sum.z = sum.z / n;
    Vector3D norm = Vector3D.create(sum).normalize();
    return norm;
  }

  Coordinate averagePoint(CoordinateSequence seq) {
    Coordinate a = Coordinate(0, 0, 0);
    int n = seq.size();
    for (int i = 0; i < n; i++) {
      a.x += seq.getOrdinate(i, CoordinateSequence.kX);
      a.y += seq.getOrdinate(i, CoordinateSequence.kY);
      a.z = (a.z + seq.getOrdinate(i, CoordinateSequence.kZ));
    }
    a.x /= n;
    a.y /= n;
    a.z /= n;
    return a;
  }

  Plane3D getPlane() {
    return _plane;
  }

  Polygon getPolygon() {
    return poly;
  }

  bool intersects(Coordinate intPt) {
    if (Location.exterior == locate(intPt, poly.getExteriorRing())) return false;

    for (int i = 0; i < poly.getNumInteriorRing(); i++) {
      if (Location.interior == locate(intPt, poly.getInteriorRingN(i))) return false;
    }
    return true;
  }

  int locate(Coordinate pt, LineString ring) {
    CoordinateSequence seq = ring.getCoordinateSequence();
    CoordinateSequence seqProj = project2(seq, _facingPlane);
    Coordinate ptProj = project(pt, _facingPlane);
    return RayCrossingCounter.locatePointInRing2(ptProj, seqProj);
  }

  bool intersects2(Coordinate pt, LineString ring) {
    CoordinateSequence seq = ring.getCoordinateSequence();
    CoordinateSequence seqProj = project2(seq, _facingPlane);
    Coordinate ptProj = project(pt, _facingPlane);
    return Location.exterior != RayCrossingCounter.locatePointInRing2(ptProj, seqProj);
  }

  static CoordinateSequence project2(CoordinateSequence seq, int facingPlane) {
    switch (facingPlane) {
      case Plane3D.kXYPlane:
        return AxisPlaneCoordinateSequence.projectToXY(seq);
      case Plane3D.kXZPlane:
        return AxisPlaneCoordinateSequence.projectToXZ(seq);
      default:
        return AxisPlaneCoordinateSequence.projectToYZ(seq);
    }
  }

  static Coordinate project(Coordinate p, int facingPlane) {
    switch (facingPlane) {
      case Plane3D.kXYPlane:
        return Coordinate(p.x, p.y);
      case Plane3D.kXZPlane:
        return Coordinate(p.x, p.z);
      default:
        return Coordinate(p.y, p.z);
    }
  }
}
