import 'package:dts/src/jts/geom/coordinate.dart';

class CoordinateList {
  final List<Coordinate> _list = [];

  CoordinateList([List<Coordinate>? coord, bool allowRepeated = true]) {
    if (coord != null) {
      add2(coord, allowRepeated);
    }
  }

  Coordinate getCoordinate(int i) => _list[i];

  void set(int index, Coordinate value) {
    _list[index] = value;
  }

  Coordinate get(int index) => _list[index];

  void add(Coordinate coord) {
    _list.add(coord);
  }

  bool add2(List<Coordinate> coord, bool allowRepeated) {
    add4(coord, allowRepeated, true);
    return true;
  }

  void add3(Coordinate coord, bool allowRepeated) {
    if (!allowRepeated) {
      if (_list.isNotEmpty) {
        Coordinate last = _list.last;
        if (last.equals2D(coord)) return;
      }
    }
    _list.add(coord);
  }

  bool add4(List<Coordinate> coord, bool allowRepeated, bool direction) {
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

  bool add5(List<Coordinate> coord, bool allowRepeated, int start, int end) {
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
      int size = _list.length;
      if (size > 0) {
        if (i > 0) {
          Coordinate prev = _list[i - 1];
          if (prev.equals2D(coord)) return;
        }
        if (i < size) {
          Coordinate next = _list[i];
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
    if (_list.isNotEmpty) {
      add3(_list[0].copy(), false);
    }
  }

  void clear() {
    _list.clear();
  }

  Coordinate remove(int index) => _list.removeAt(index);

  List<Coordinate> toCoordinateList([bool isForward = true]) {
    if (isForward) {
      return List.from(_list);
    }
    return _list.reversed.toList();
  }

  CoordinateList clone() {
    CoordinateList clone = CoordinateList();
    clone._list.addAll(_list.map((e) => e.clone()));
    return clone;
  }

  int get size => _list.length;

  Coordinate get last => _list.last;

  List<Coordinate> get rawList => _list;
}
