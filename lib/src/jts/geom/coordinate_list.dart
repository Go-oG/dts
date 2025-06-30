import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';

class CoordinateList {
  final List<Coordinate> _list = [];

  CoordinateList([Array<Coordinate>? coord, bool allowRepeated = true]) {
    if (coord != null) {
      add2(coord, allowRepeated);
    }
  }

  Coordinate getCoordinate(int i) {
    return (_list.get(i));
  }

  void add(Coordinate coord) {
    _list.add(coord);
  }

  void set(int index, Coordinate value) {
    _list[index] = value;
  }

  Coordinate get(int index) => _list[index];

  bool add2(Array<Coordinate> coord, bool allowRepeated) {
    add4(coord, allowRepeated, true);
    return true;
  }

  void add3(Coordinate coord, bool allowRepeated) {
    if (!allowRepeated) {
      if (_list.size >= 1) {
        Coordinate last = ((_list.get(_list.size - 1)));
        if (last.equals2D(coord)) return;
      }
    }
    _list.add(coord);
  }

  bool add4(Array<Coordinate> coord, bool allowRepeated, bool direction) {
    if (direction) {
      for (int i = 0; i < coord.length; i++) {
        add3(coord[i], allowRepeated);
      }
    } else {
      for (int i = coord.length - 1; i >= 0; i--) {
        add3(coord[i], allowRepeated);
      }
    }
    return true;
  }

  bool add5(Array<Coordinate> coord, bool allowRepeated, int start, int end) {
    int inc = 1;
    if (start > end) inc = -1;

    for (int i = start; i != end; i += inc) {
      add3(coord[i], allowRepeated);
    }
    return true;
  }

  bool add6(Coordinate obj, bool allowRepeated) {
    add3(obj, allowRepeated);
    return true;
  }

  void add7(int i, Coordinate coord, bool allowRepeated) {
    if (!allowRepeated) {
      int size = _list.size;
      if (size > 0) {
        if (i > 0) {
          Coordinate prev = ((_list.get(i - 1)));
          if (prev.equals2D(coord)) return;
        }
        if (i < size) {
          Coordinate next = ((_list.get(i)));
          if (next.equals2D(coord)) return;
        }
      }
    }
    _list.insert(i, coord);
  }

  bool addAll(List<Coordinate> coll, bool allowRepeated) {
    bool isChanged = false;
    for (var item in coll) {
      add3(item, allowRepeated);
      isChanged = true;
    }
    return isChanged;
  }

  void closeRing() {
    if (_list.size > 0) {
      Coordinate duplicate = _list.get(0).copy();
      add3(duplicate, false);
    }
  }

  void clear() {
    _list.clear();
  }

  Coordinate remove(int index) => _list.removeAt(index);

  Array<Coordinate> toCoordinateArray() {
    return _list.toArray();
  }

  Array<Coordinate> toCoordinateArray2(bool isForward) {
    if (isForward) {
      return toCoordinateArray();
    }
    int size = _list.size;
    Array<Coordinate> pts = Array(size);
    for (int i = 0; i < size; i++) {
      pts[i] = _list.get((size - i) - 1);
    }
    return pts;
  }

  CoordinateList clone() {
    CoordinateList clone = CoordinateList();
    for (int i = 0; i < _list.size; i++) {
      clone._list.add(_list.get(i).clone());
    }
    return clone;
  }

  int get size => _list.length;

  Coordinate get last => _list.last;

  List<Coordinate> get rawList => _list;
}
