 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';

class Area {
  Area._();

  static double ofRing(Array<Coordinate> ring) {
    return Math.abs(ofRingSigned(ring));
  }

  static double ofRing2(CoordinateSequence ring) {
    return Math.abs(ofRingSigned2(ring));
  }

  static double ofRingSigned(Array<Coordinate> ring) {
    if (ring.length < 3) {
      return 0.0;
    }

    double sum = 0.0;
    double x0 = ring[0].x;
    for (int i = 1; i < (ring.length - 1); i++) {
      double x = ring[i].x - x0;
      double y1 = ring[i + 1].y;
      double y2 = ring[i - 1].y;
      sum += x * (y2 - y1);
    }
    return sum / 2.0;
  }

  static double ofRingSigned2(CoordinateSequence ring) {
    int n = ring.size();
    if (n < 3) {
      return 0.0;
    }

    Coordinate p0 = ring.createCoordinate();
    Coordinate p1 = ring.createCoordinate();
    Coordinate p2 = ring.createCoordinate();
    ring.getCoordinate2(0, p1);
    ring.getCoordinate2(1, p2);
    double x0 = p1.x;
    p2.x -= x0;
    double sum = 0.0;
    for (int i = 1; i < (n - 1); i++) {
      p0.y = p1.y;
      p1.x = p2.x;
      p1.y = p2.y;
      ring.getCoordinate2(i + 1, p2);
      p2.x -= x0;
      sum += p1.x * (p0.y - p2.y);
    }
    return sum / 2.0;
  }
}
