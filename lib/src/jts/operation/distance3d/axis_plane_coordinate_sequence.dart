 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/envelope.dart';

class AxisPlaneCoordinateSequence extends CoordinateSequence {
  static CoordinateSequence projectToXY(CoordinateSequence seq) {
    return AxisPlaneCoordinateSequence(seq, _XY_INDEX);
  }

  static CoordinateSequence projectToXZ(CoordinateSequence seq) {
    return AxisPlaneCoordinateSequence(seq, _XZ_INDEX);
  }

  static CoordinateSequence projectToYZ(CoordinateSequence seq) {
    return AxisPlaneCoordinateSequence(seq, _YZ_INDEX);
  }

  static final Array<int> _XY_INDEX = [0, 1].toArray();

  static final Array<int> _XZ_INDEX = [0, 2].toArray();

  static final Array<int> _YZ_INDEX = [1, 2].toArray();

  final CoordinateSequence _seq;

  final Array<int> _indexMap;

  AxisPlaneCoordinateSequence(this._seq, this._indexMap);

  @override
  int getDimension() {
    return 2;
  }

  @override
  Coordinate getCoordinate(int i) {
    return getCoordinateCopy(i);
  }

  @override
  Coordinate getCoordinateCopy(int i) {
    return Coordinate(getX(i), getY(i), getZ(i));
  }

  @override
  void getCoordinate2(int index, Coordinate coord) {
    coord.x = getOrdinate(index, CoordinateSequence.X);
    coord.y = getOrdinate(index, CoordinateSequence.Y);
    coord.setZ(getOrdinate(index, CoordinateSequence.Z));
  }

  @override
  double getX(int index) {
    return getOrdinate(index, CoordinateSequence.X);
  }

  @override
  double getY(int index) {
    return getOrdinate(index, CoordinateSequence.Y);
  }

  @override
  double getZ(int index) {
    return getOrdinate(index, CoordinateSequence.Z);
  }

  @override
  double getOrdinate(int index, int ordinateIndex) {
    if (ordinateIndex > 1) return 0;

    return _seq.getOrdinate(index, _indexMap[ordinateIndex]);
  }

  @override
  int size() {
    return _seq.size();
  }

  @override
  void setOrdinate(int index, int ordinateIndex, double value) {
    throw UnsupportedError("");
  }

  @override
  Array<Coordinate> toCoordinateArray() {
    throw UnsupportedError("");
  }

  @override
  Envelope expandEnvelope(Envelope env) {
    throw UnsupportedError("");
  }

  @override
  Object clone() {
    throw UnsupportedError("");
  }

  @override
  AxisPlaneCoordinateSequence copy() {
    throw UnsupportedError("");
  }
}
