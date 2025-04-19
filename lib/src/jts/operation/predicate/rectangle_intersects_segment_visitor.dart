import 'package:dts/src/jts/algorithm/rectangle_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/polygon.dart';
import 'package:dts/src/jts/geom/util/linear_component_extracter.dart';
import 'package:dts/src/jts/geom/util/short_circuited_geometry_visitor.dart';

class RectangleIntersectsSegmentVisitor extends ShortCircuitedGeometryVisitor {
  late Envelope rectEnv;

  late RectangleLineIntersector _rectIntersector;

  bool hasIntersection = false;

  RectangleIntersectsSegmentVisitor(Polygon rectangle) {
    rectEnv = rectangle.getEnvelopeInternal();
    _rectIntersector = RectangleLineIntersector(rectEnv);
  }

  bool intersects() {
    return hasIntersection;
  }

  @override
  void visit(Geometry geom) {
    Envelope elementEnv = geom.getEnvelopeInternal();
    if (!rectEnv.intersects(elementEnv)) {
      return;
    }

    List<LineString> lines = LinearComponentExtracter.getLines(geom);
    checkIntersectionWithLineStrings(lines);
  }

  void checkIntersectionWithLineStrings(List<LineString> lines) {
    for (Iterator i = lines.iterator; i.moveNext();) {
      LineString testLine = i.current;
      checkIntersectionWithSegments(testLine);
      if (hasIntersection) {
        return;
      }
    }
  }

  void checkIntersectionWithSegments(LineString testLine) {
    CoordinateSequence seq1 = testLine.getCoordinateSequence();
    Coordinate p0 = seq1.createCoordinate();
    Coordinate p1 = seq1.createCoordinate();
    for (int j = 1; j < seq1.size(); j++) {
      seq1.getCoordinate2(j - 1, p0);
      seq1.getCoordinate2(j, p1);
      if (_rectIntersector.intersects(p0, p1)) {
        hasIntersection = true;
        return;
      }
    }
  }

  @override
  bool isDone() {
    return hasIntersection;
  }
}
