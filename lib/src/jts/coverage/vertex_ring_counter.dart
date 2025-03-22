 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';

class VertexRingCounter implements CoordinateSequenceFilter {
  static Map<Coordinate, int> count(Array<Geometry> geoms) {
    Map<Coordinate, int> vertexRingCount = {};
    VertexRingCounter counter = VertexRingCounter(vertexRingCount);
    for (Geometry geom in geoms) {
      geom.apply2(counter);
    }
    return vertexRingCount;
  }

  final Map<Coordinate, int> _vertexRingCount;

  VertexRingCounter(this._vertexRingCount);

  @override
  void filter(CoordinateSequence seq, int i) {
    if (CoordinateSequences.isRing(seq) && (i == 0)) {
      return;
    }

    Coordinate v = seq.getCoordinate(i);
    int count = _vertexRingCount.containsKey(v) ? _vertexRingCount.get(v)! : 0;
    count++;
    _vertexRingCount.put(v, count);
  }

  @override
  bool isDone() {
    return false;
  }

  @override
  bool isGeometryChanged() {
    return false;
  }
}
