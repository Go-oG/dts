 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/lineal.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'linear_geometry_builder.dart';
import 'linear_iterator.dart';
import 'linear_location.dart';

class ExtractLineByLocation {
  static Geometry extract(Geometry line, LinearLocation start, LinearLocation end) {
    ExtractLineByLocation ls = ExtractLineByLocation(line);
    return ls.extract2(start, end);
  }

  final Geometry _line;

  ExtractLineByLocation(this._line);

  Geometry extract2(LinearLocation start, LinearLocation end) {
    if (end.compareTo(start) < 0) {
      return reverse(computeLinear(end, start))!;
    }
    return computeLinear(start, end);
  }

  Geometry? reverse(Geometry linear) {
    if (linear is Lineal) return linear.reverse();

    Assert.shouldNeverReachHere2("non-linear geometry encountered");
    return null;
  }

  LineString computeLine(LinearLocation start, LinearLocation end) {
    Array<Coordinate> coordinates = _line.getCoordinates();
    CoordinateList newCoordinates = CoordinateList();
    int startSegmentIndex = start.getSegmentIndex();
    if (start.getSegmentFraction() > 0.0) startSegmentIndex += 1;

    int lastSegmentIndex = end.getSegmentIndex();
    if (end.getSegmentFraction() == 1.0) lastSegmentIndex += 1;

    if (lastSegmentIndex >= coordinates.length) lastSegmentIndex = coordinates.length - 1;

    if (!start.isVertex()) newCoordinates.add(start.getCoordinate(_line));

    for (int i = startSegmentIndex; i <= lastSegmentIndex; i++) {
      newCoordinates.add(coordinates[i]);
    }
    if (!end.isVertex()) newCoordinates.add(end.getCoordinate(_line));

    if (newCoordinates.size <= 0) newCoordinates.add(start.getCoordinate(_line));

    Array<Coordinate> newCoordinateArray = newCoordinates.toCoordinateArray();
    if (newCoordinateArray.length <= 1) {
      newCoordinateArray = [newCoordinateArray[0], newCoordinateArray[0]].toArray();
    }
    return _line.factory.createLineString2(newCoordinateArray);
  }

  Geometry computeLinear(LinearLocation start, LinearLocation end) {
    LinearGeometryBuilder builder = LinearGeometryBuilder(_line.factory);
    builder.setFixInvalidLines(true);
    if (!start.isVertex()) builder.add(start.getCoordinate(_line));

    for (LinearIterator it = LinearIterator.of2(_line, start); it.hasNext(); it.next()) {
      if (end.compareLocationValues(it.getComponentIndex(), it.getVertexIndex(), 0.0) < 0) break;

      Coordinate pt = it.getSegmentStart();
      builder.add(pt);
      if (it.isEndOfLine()) builder.endLine();
    }
    if (!end.isVertex()) builder.add(end.getCoordinate(_line));

    return builder.getGeometry();
  }
}
