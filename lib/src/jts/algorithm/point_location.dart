import '../geom/coordinate.dart';
import '../geom/coordinate_sequence.dart';
import '../geom/envelope.dart';
import '../geom/location.dart';
import 'orientation.dart';
import 'ray_crossing_counter.dart';

class PointLocation {
  static bool isOnSegment(Coordinate p, Coordinate p0, Coordinate p1) {
    if (!Envelope.intersects3(p0, p1, p)) {
      return false;
    }

    if (p.equals2D(p0)) {
      return true;
    }

    bool isOnLine = Orientation.collinear == Orientation.index(p0, p1, p);
    return isOnLine;
  }

  static bool isOnLine(Coordinate p, List<Coordinate> line) {
    for (int i = 1; i < line.length; i++) {
      Coordinate p0 = line[i - 1];
      Coordinate p1 = line[i];
      if (isOnSegment(p, p0, p1)) {
        return true;
      }
    }
    return false;
  }

  static bool isOnLine2(Coordinate p, CoordinateSequence line) {
    Coordinate p0 = Coordinate();
    Coordinate p1 = Coordinate();
    int n = line.size();
    for (int i = 1; i < n; i++) {
      line.getCoordinate2(i - 1, p0);
      line.getCoordinate2(i, p1);
      if (isOnSegment(p, p0, p1)) {
        return true;
      }
    }
    return false;
  }

  static bool isInRing(Coordinate p, List<Coordinate> ring) {
    return PointLocation.locateInRing(p, ring) != Location.exterior;
  }

  static int locateInRing(Coordinate p, List<Coordinate> ring) {
    return RayCrossingCounter.locatePointInRing(p, ring);
  }
}
