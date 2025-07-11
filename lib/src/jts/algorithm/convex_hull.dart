import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_arrays.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'orientation.dart';
import 'point_location.dart';

final class ConvexHull {
  static const int _tuningReduceSize = 50;

  final GeometryFactory geomFactory;

  final Array<Coordinate> _inputPts;

  ConvexHull.of(Geometry geometry) : this(geometry.getCoordinates(), geometry.factory);

  ConvexHull(this._inputPts, this.geomFactory);

  Geometry getConvexHull() {
    Geometry? fewPointsGeom = _createFewPointsResult();
    if (fewPointsGeom != null) {
      return fewPointsGeom;
    }

    Array<Coordinate> reducedPts = _inputPts;
    if (_inputPts.length > _tuningReduceSize) {
      reducedPts = _reduce(_inputPts);
    } else {
      reducedPts = _extractUnique(_inputPts)!;
    }
    Array<Coordinate> sortedPts = _preSort(reducedPts);

    Stack<Coordinate> cHS = _grahamScan(sortedPts);

    Array<Coordinate> cH = toCoordinateArray(cHS);

    return _lineOrPolygon(cH);
  }

  Geometry? _createFewPointsResult() {
    Array<Coordinate>? uniquePts = _extractUnique2(_inputPts, 2);
    if (uniquePts == null) {
      return null;
    } else if (uniquePts.isEmpty) {
      return geomFactory.createGeomCollection();
    } else if (uniquePts.length == 1) {
      return geomFactory.createPoint2(uniquePts[0]);
    } else {
      return geomFactory.createLineString2(uniquePts);
    }
  }

  static Array<Coordinate>? _extractUnique(Array<Coordinate> pts) {
    return _extractUnique2(pts, -1);
  }

  static Array<Coordinate>? _extractUnique2(Array<Coordinate> pts, int maxPts) {
    Set<Coordinate> uniquePts = <Coordinate>{};

    for (Coordinate pt in pts) {
      uniquePts.add(pt);
      if ((maxPts >= 0) && (uniquePts.length > maxPts)) {
        return null;
      }
    }
    return CoordinateArrays.toCoordinateArray(uniquePts.toList());
  }

  Array<Coordinate> toCoordinateArray(Stack<Coordinate> stack) {
    Array<Coordinate> coordinates = Array<Coordinate>(stack.size);
    for (int i = 0; i < stack.size; i++) {
      Coordinate coordinate = stack.get(i);
      coordinates[i] = coordinate;
    }
    return coordinates;
  }

  Array<Coordinate> _reduce(Array<Coordinate> inputPts) {
    Array<Coordinate>? innerPolyPts = _computeInnerOctolateralRing(inputPts);
    if (innerPolyPts == null) {
      return inputPts.copy();
    }

    Set<Coordinate> reducedSet = <Coordinate>{};
    reducedSet.addAll(innerPolyPts);

    for (var item in inputPts) {
      if (!PointLocation.isInRing(item, innerPolyPts)) {
        reducedSet.add(item);
      }
    }
    Array<Coordinate> reducedPts = CoordinateArrays.toCoordinateArray(reducedSet.toList());
    if (reducedPts.length < 3) {
      return _padArray3(reducedPts);
    }

    return reducedPts;
  }

  Array<Coordinate> _padArray3(Array<Coordinate> pts) {
    Array<Coordinate> pad = Array<Coordinate>(3);
    for (int i = 0; i < pad.length; i++) {
      if (i < pts.length) {
        pad[i] = pts[i];
      } else {
        pad[i] = pts[0];
      }
    }
    return pad;
  }

  Array<Coordinate> _preSort(Array<Coordinate> pts) {
    Coordinate t;
    for (int i = 1; i < pts.length; i++) {
      if ((pts[i].y < pts[0].y) || ((pts[i].y == pts[0].y) && (pts[i].x < pts[0].x))) {
        t = pts[0];
        pts[0] = pts[i];
        pts[i] = t;
      }
    }

    Array.sortRange(pts, 1, pts.length, _RadialComparator(pts[0]).compare);
    return pts;
  }

  Stack<Coordinate> _grahamScan(Array<Coordinate> c) {
    Coordinate p;
    Stack<Coordinate> ps = Stack();
    ps.push(c[0]);
    ps.push(c[1]);
    ps.push(c[2]);
    for (int i = 3; i < c.length; i++) {
      Coordinate cp = c[i];
      p = ps.pop();
      while (ps.isNotEmpty && (Orientation.index(ps.peek(), p, cp) > 0)) {
        p = ps.pop();
      }
      ps.push(p);
      ps.push(cp);
    }
    ps.push(c[0]);
    return ps;
  }

  bool _isBetween(Coordinate c1, Coordinate c2, Coordinate c3) {
    if (Orientation.index(c1, c2, c3) != 0) {
      return false;
    }
    if (c1.x != c3.x) {
      if ((c1.x <= c2.x) && (c2.x <= c3.x)) {
        return true;
      }
      if ((c3.x <= c2.x) && (c2.x <= c1.x)) {
        return true;
      }
    }
    if (c1.y != c3.y) {
      if ((c1.y <= c2.y) && (c2.y <= c3.y)) {
        return true;
      }
      if ((c3.y <= c2.y) && (c2.y <= c1.y)) {
        return true;
      }
    }
    return false;
  }

  Array<Coordinate>? _computeInnerOctolateralRing(Array<Coordinate> inputPts) {
    Array<Coordinate> octPts = _computeInnerOctolateralPts(inputPts);
    CoordinateList coordList = CoordinateList();
    coordList.add2(octPts, false);
    if (coordList.size < 3) {
      return null;
    }
    coordList.closeRing();
    return coordList.toCoordinateArray();
  }

  Array<Coordinate> _computeInnerOctolateralPts(Array<Coordinate> inputPts) {
    Array<Coordinate> pts = Array<Coordinate>(8);
    pts.fillRange(0, pts.length, inputPts[0]);

    for (int i = 1; i < inputPts.length; i++) {
      final item = inputPts[i];
      if (item.x < pts[0].x) {
        pts[0] = item;
      }
      if ((item.x - item.y) < (pts[1].x - pts[1].y)) {
        pts[1] = item;
      }
      if (item.y > pts[2].y) {
        pts[2] = item;
      }
      if ((item.x + item.y) > (pts[3].x + pts[3].y)) {
        pts[3] = item;
      }
      if (item.x > pts[4].x) {
        pts[4] = item;
      }
      if ((item.x - item.y) > (pts[5].x - pts[5].y)) {
        pts[5] = item;
      }
      if (item.y < pts[6].y) {
        pts[6] = item;
      }
      if ((item.x + item.y) < (pts[7].x + pts[7].y)) {
        pts[7] = item;
      }
    }
    return pts;
  }

  Geometry _lineOrPolygon(Array<Coordinate> coordinates) {
    coordinates = _cleanRing(coordinates);
    if (coordinates.length == 3) {
      return geomFactory.createLineString2([coordinates[0], coordinates[1]].toArray());
    }
    LinearRing linearRing = geomFactory.createLinearRings(coordinates);
    return geomFactory.createPolygon(linearRing);
  }

  Array<Coordinate> _cleanRing(Array<Coordinate> original) {
    Assert.equals(original[0], original[original.length - 1]);
    List<Coordinate> cleanedRing = <Coordinate>[];
    Coordinate? previousDistinctCoordinate;
    for (int i = 0; i <= (original.length - 2); i++) {
      Coordinate currentCoordinate = original[i];
      Coordinate nextCoordinate = original[i + 1];
      if (currentCoordinate == nextCoordinate) {
        continue;
      }
      if ((previousDistinctCoordinate != null) &&
          _isBetween(previousDistinctCoordinate, currentCoordinate, nextCoordinate)) {
        continue;
      }
      cleanedRing.add(currentCoordinate);
      previousDistinctCoordinate = currentCoordinate;
    }
    cleanedRing.add(original[original.length - 1]);
    return cleanedRing.toArray();
  }
}

class _RadialComparator {
  Coordinate origin;

  _RadialComparator(this.origin);

  int compare(Coordinate p1, Coordinate p2) {
    int comp = polarCompare(origin, p1, p2);
    return comp;
  }

  int polarCompare(Coordinate o, Coordinate p, Coordinate q) {
    int orient = Orientation.index(o, p, q);
    if (orient == Orientation.counterClockwise) {
      return 1;
    }

    if (orient == Orientation.clockwise) {
      return -1;
    }

    if (p.y > q.y) {
      return 1;
    }

    if (p.y < q.y) {
      return -1;
    }

    if (p.x > q.x) {
      return 1;
    }

    if (p.x < q.x) {
      return -1;
    }

    return 0;
  }
}
