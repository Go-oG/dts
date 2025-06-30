import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

import 'octant.dart';
import 'segment_string.dart';

class BasicSegmentString extends SegmentString {
  Array<Coordinate> pts;

  Object? data;

  BasicSegmentString(this.pts, this.data);

  @override
  Object? getData() {
    return data;
  }

  @override
  void setData(Object? data) {
    this.data = data;
  }

  @override
  int size() {
    return pts.length;
  }

  @override
  Coordinate getCoordinate(int i) {
    return pts[i];
  }

  @override
  Array<Coordinate> getCoordinates() {
    return pts;
  }

  @override
  bool isClosed() {
    return pts[0] == pts[pts.length - 1];
  }

  int getSegmentOctant(int index) {
    if (index == (pts.length - 1)) return -1;

    return Octant.octant2(getCoordinate(index), getCoordinate(index + 1));
  }
}
