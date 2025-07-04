import 'dart:math';

import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/index/kd_tree.dart';

import 'hot_pixel.dart';

class HotPixelIndex {
  final PrecisionModel _precModel;

  double scaleFactor = 0;

  final KdTree _index = KdTree();

  HotPixelIndex(this._precModel) {
    scaleFactor = _precModel.getScale();
  }

  void add2(Array<Coordinate> pts) {
    Iterator<Coordinate> it = CoordinateShuffler(pts);
    while (it.moveNext()) {
      add(it.current);
    }
  }

  void addNodes(List<Coordinate> pts) {
    for (Coordinate pt in pts) {
      HotPixel hp = add(pt);
      hp.setToNode();
    }
  }

  HotPixel add(Coordinate p) {
    Coordinate pRound = round(p);
    HotPixel? hp = find(pRound);
    if (hp != null) {
      hp.setToNode();
      return hp;
    }
    hp = HotPixel(pRound, scaleFactor);
    _index.insert2(hp.getCoordinate(), hp);
    return hp;
  }

  HotPixel? find(Coordinate pixelPt) {
    final kdNode = _index.query(pixelPt);
    if (kdNode == null) {
      return null;
    }

    return (kdNode.getData() as HotPixel);
  }

  Coordinate round(Coordinate pt) {
    Coordinate p2 = pt.copy();
    _precModel.makePrecise(p2);
    return p2;
  }

  void query(Coordinate p0, Coordinate p1, KdNodeVisitor visitor) {
    Envelope queryEnv = Envelope.of(p0, p1);
    queryEnv.expandBy(1.0 / scaleFactor);
    _index.query3(queryEnv, visitor);
  }
}

final class CoordinateShuffler implements Iterator<Coordinate> {
  final Random _rnd = Random(13);
  final Array<Coordinate> coordinates;
  late final Array<int> _indices;
  late int index;

  CoordinateShuffler(this.coordinates) {
    _indices = Array(coordinates.length);
    for (int i = 0; i < coordinates.length; i++) {
      _indices[i] = i;
    }
    index = coordinates.length - 1;
  }

  bool _hasNext() {
    return index >= 0;
  }

  Coordinate _next() {
    int j = _rnd.nextInt(index + 1);
    Coordinate res = coordinates[_indices[j]];
    _indices[j] = _indices[index--];
    return res;
  }

  @override
  Coordinate get current => _next();

  @override
  bool moveNext() {
    return _hasNext();
  }
}
