 import 'package:d_util/d_util.dart';

import '../geom/coordinate.dart';

abstract class SegmentString {
  Object? getData();

  void setData(Object data);

  int size();

  Coordinate getCoordinate(int i);

  Array<Coordinate> getCoordinates();

  bool isClosed();

  Coordinate prevInRing(int index) {
    int prevIndex = index - 1;
    if (prevIndex < 0) {
      prevIndex = size() - 2;
    }
    return getCoordinate(prevIndex);
  }

  Coordinate nextInRing(int index) {
    int nextIndex = index + 1;
    if (nextIndex > (size() - 1)) {
      nextIndex = 1;
    }
    return getCoordinate(nextIndex);
  }
}
