import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/envelope.dart';

class AxisPlaneCoordinateSequence extends CoordinateSequence {
  static CoordinateSequence projectToXY(CoordinateSequence seq) {
    return AxisPlaneCoordinateSequence(seq, _kXYIndex);
  }

  static CoordinateSequence projectToXZ(CoordinateSequence seq) {
    return AxisPlaneCoordinateSequence(seq, _kXZIndex);
  }

  static CoordinateSequence projectToYZ(CoordinateSequence seq) {
    return AxisPlaneCoordinateSequence(seq, _kYZIndex);
  }

  static final List<int> _kXYIndex = const [0, 1];

  static final List<int> _kXZIndex = const [0, 2];

  static final List<int> _kYZIndex = const [1, 2];

  final CoordinateSequence _seq;

  final List<int> _indexMap;

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
    coord.x = getOrdinate(index, CoordinateSequence.kX);
    coord.y = getOrdinate(index, CoordinateSequence.kY);
    coord.z = getOrdinate(index, CoordinateSequence.kZ);
  }

  @override
  double getX(int index) {
    return getOrdinate(index, CoordinateSequence.kX);
  }

  @override
  double getY(int index) {
    return getOrdinate(index, CoordinateSequence.kY);
  }

  @override
  double getZ(int index) {
    return getOrdinate(index, CoordinateSequence.kZ);
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
  List<Coordinate> toCoordinateArray() {
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
