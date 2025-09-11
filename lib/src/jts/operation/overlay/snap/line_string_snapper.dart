import 'package:dts/src/jts/algorithm/distance.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/line_string.dart';

class LineStringSnapper {
  double _snapTolerance = 0.0;

  double _snapToleranceSq = 0.0;

  List<Coordinate> _srcPts;

  bool _allowSnappingToSourceVertices = false;

  bool _isClosed = false;

  LineStringSnapper.of(LineString srcLine, double snapTolerance)
      : this(srcLine.getCoordinates(), snapTolerance);

  LineStringSnapper(this._srcPts, this._snapTolerance) {
    _isClosed = isClosed(_srcPts);
    _snapToleranceSq = _snapTolerance * _snapTolerance;
  }

  void setAllowSnappingToSourceVertices(bool allowSnappingToSourceVertices) {
    _allowSnappingToSourceVertices = allowSnappingToSourceVertices;
  }

  static bool isClosed(List<Coordinate> pts) {
    if (pts.length <= 1) return false;

    return pts[0].equals2D(pts[pts.length - 1]);
  }

  List<Coordinate> snapTo(List<Coordinate> snapPts) {
    CoordinateList coordList = CoordinateList(_srcPts);
    snapVertices(coordList, snapPts);
    snapSegments(coordList, snapPts);
    return coordList.toCoordinateList();
  }

  void snapVertices(CoordinateList srcCoords, List<Coordinate> snapPts) {
    int end = (_isClosed) ? srcCoords.size - 1 : srcCoords.size;
    for (int i = 0; i < end; i++) {
      Coordinate srcPt = srcCoords.get(i);
      Coordinate? snapVert = findSnapForVertex(srcPt, snapPts);
      if (snapVert != null) {
        srcCoords.set(i, Coordinate.of(snapVert));
        if ((i == 0) && _isClosed) {
          srcCoords.set(srcCoords.size - 1, Coordinate.of(snapVert));
        }
      }
    }
  }

  Coordinate? findSnapForVertex(Coordinate pt, List<Coordinate> snapPts) {
    for (int i = 0; i < snapPts.length; i++) {
      if (pt.equals2D(snapPts[i])) return null;

      if (pt.distance(snapPts[i]) < _snapTolerance) return snapPts[i];
    }
    return null;
  }

  void snapSegments(CoordinateList srcCoords, List<Coordinate> snapPts) {
    if (snapPts.isEmpty) return;

    int distinctPtCount = snapPts.length;
    if (snapPts[0].equals2D(snapPts[snapPts.length - 1])) {
      distinctPtCount = snapPts.length - 1;
    }

    for (int i = 0; i < distinctPtCount; i++) {
      Coordinate snapPt = snapPts[i];
      int index = findSegmentIndexToSnap(snapPt, srcCoords);
      if (index >= 0) {
        srcCoords.add7(index + 1, Coordinate.of(snapPt), false);
      }
    }
  }

  int findSegmentIndexToSnap(Coordinate snapPt, CoordinateList srcCoords) {
    double minDist = double.maxFinite;
    int snapIndex = -1;
    for (int i = 0; i < (srcCoords.size - 1); i++) {
      final Coordinate p0 = srcCoords.get(i);
      final Coordinate p1 = srcCoords.get(i + 1);
      if (p0.equals2D(snapPt) || p1.equals2D(snapPt)) {
        if (_allowSnappingToSourceVertices) {
          continue;
        } else {
          return -1;
        }
      }
      double dist = Distance.pointToSegmentSq(snapPt, p0, p1);
      if ((dist < _snapToleranceSq) && (dist < minDist)) {
        minDist = dist;
        snapIndex = i;
      }
    }
    return snapIndex;
  }
}
