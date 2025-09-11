import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/position.dart';

class TopologyLocation {
  late Array<int> location;

  TopologyLocation(TopologyLocation gl) {
    init(gl.location.length);
    for (int i = 0; i < location.length; i++) {
      location[i] = gl.location[i];
    }
  }

  TopologyLocation.of(int on) {
    init(1);
    location[Position.on] = on;
  }

  TopologyLocation.of2(Array<int> location) {
    init(location.length);
  }

  TopologyLocation.of3(int on, int left, int right) {
    init(3);
    location[Position.on] = on;
    location[Position.left] = left;
    location[Position.right] = right;
  }

  void init(int size) {
    location = Array(size);
    setAllLocations(Location.none);
  }

  int get(int posIndex) {
    if (posIndex < location.length) return location[posIndex];

    return Location.none;
  }

  bool isNull() {
    for (int i = 0; i < location.length; i++) {
      if (location[i] != Location.none) return false;
    }
    return true;
  }

  bool isAnyNull() {
    for (int i = 0; i < location.length; i++) {
      if (location[i] == Location.none) return true;
    }
    return false;
  }

  bool isEqualOnSide(TopologyLocation le, int locIndex) {
    return location[locIndex] == le.location[locIndex];
  }

  bool isArea() {
    return location.length > 1;
  }

  bool isLine() {
    return location.length == 1;
  }

  void flip() {
    if (location.length <= 1) return;

    int temp = location[Position.left];
    location[Position.left] = location[Position.right];
    location[Position.right] = temp;
  }

  void setAllLocations(int locValue) {
    for (int i = 0; i < location.length; i++) {
      location[i] = locValue;
    }
  }

  void setAllLocationsIfNull(int locValue) {
    for (int i = 0; i < location.length; i++) {
      if (location[i] == Location.none) location[i] = locValue;
    }
  }

  void setLocation2(int locIndex, int locValue) {
    location[locIndex] = locValue;
  }

  void setLocation(int locValue) {
    setLocation2(Position.on, locValue);
  }

  Array<int> getLocations() {
    return location;
  }

  void setLocations(int on, int left, int right) {
    location[Position.on] = on;
    location[Position.left] = left;
    location[Position.right] = right;
  }

  bool allPositionsEqual(int loc) {
    for (int i = 0; i < location.length; i++) {
      if (location[i] != loc) return false;
    }
    return true;
  }

  void merge(TopologyLocation gl) {
    if (gl.location.length > location.length) {
      Array<int> newLoc = Array(3);
      newLoc[Position.on] = location[Position.on];
      newLoc[Position.left] = Location.none;
      newLoc[Position.right] = Location.none;
      location = newLoc;
    }
    for (int i = 0; i < location.length; i++) {
      if ((location[i] == Location.none) && (i < gl.location.length)) {
        location[i] = gl.location[i];
      }
    }
  }

  @override
  String toString() {
    StringBuffer buf = StringBuffer();
    if (location.length > 1) {
      buf.write(Location.toLocationSymbol(location[Position.left]));
    }

    buf.write(Location.toLocationSymbol(location[Position.on]));
    if (location.length > 1) {
      buf.write(Location.toLocationSymbol(location[Position.right]));
    }
    return buf.toString();
  }
}
