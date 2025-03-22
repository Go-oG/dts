 import 'package:d_util/d_util.dart';

import 'coordinate.dart';
import 'coordinate_arrays.dart';
import 'envelope.dart';

abstract class CoordinateSequence {
  static const int X = 0;
  static const int Y = 1;
  static const int Z = 2;
  static const int M = 3;

  int getDimension();

  int getMeasures() {
    return 0;
  }

  bool hasZ() {
    return (getDimension() - getMeasures()) > 2;
  }

  bool hasM() {
    return getMeasures() > 0;
  }

  Coordinate createCoordinate() {
    return Coordinates.create2(getDimension(), getMeasures());
  }

  Coordinate getCoordinate(int i);

  Coordinate getCoordinateCopy(int i);

  void getCoordinate2(int index, Coordinate coord);

  double getX(int index);

  double getY(int index);

  double getZ(int index) {
    if (hasZ()) {
      return getOrdinate(index, 2);
    } else {
      return double.nan;
    }
  }

  double getM(int index) {
    if (hasM()) {
      final int mIndex = getDimension() - getMeasures();
      return getOrdinate(index, mIndex);
    } else {
      return double.nan;
    }
  }

  double getOrdinate(int index, int ordinateIndex);

  int size();

  void setOrdinate(int index, int ordinateIndex, double value);

  Array<Coordinate> toCoordinateArray();

  Envelope expandEnvelope(Envelope env);

  Object clone();

  CoordinateSequence copy();
}

abstract class CoordinateSequenceFactory {
  CoordinateSequence create(Array<Coordinate>? coordinates);

  CoordinateSequence create2(CoordinateSequence coordSeq);

  CoordinateSequence create3(int size, int dimension);

  CoordinateSequence create4(int size, int dimension, int measures) {
    return create3(size, dimension);
  }
}

abstract interface class CoordinateSequenceFilter {
  void filter(CoordinateSequence seq, int i);

  bool isDone();

  bool isGeometryChanged();
}

class CoordinateSequenceComparator implements CComparator<CoordinateSequence> {
  static int compareS(double a, double b) {
    if (a < b) return -1;

    if (a > b) return 1;

    if (Double.isNaN(a)) {
      if (Double.isNaN(b)) return 0;

      return -1;
    }
    if (Double.isNaN(b)) return 1;

    return 0;
  }

  int dimensionLimit;

  CoordinateSequenceComparator([this.dimensionLimit = Integer.maxValue]);

  @override
  int compare(CoordinateSequence s1, CoordinateSequence s2) {
    int size1 = s1.size();
    int size2 = s2.size();
    int dim1 = s1.getDimension();
    int dim2 = s2.getDimension();
    int minDim = dim1;
    if (dim2 < minDim) minDim = dim2;

    bool dimLimited = false;
    if (dimensionLimit <= minDim) {
      minDim = dimensionLimit;
      dimLimited = true;
    }
    if (!dimLimited) {
      if (dim1 < dim2) return -1;

      if (dim1 > dim2) return 1;
    }
    int i = 0;
    while ((i < size1) && (i < size2)) {
      int ptComp = compareCoordinate(s1, s2, i, minDim);
      if (ptComp != 0) return ptComp;

      i++;
    }
    if (i < size1) return 1;

    if (i < size2) return -1;

    return 0;
  }

  int compareCoordinate(CoordinateSequence s1, CoordinateSequence s2, int i, int dimension) {
    for (int d = 0; d < dimension; d++) {
      double ord1 = s1.getOrdinate(i, d);
      double ord2 = s2.getOrdinate(i, d);
      int comp = compareS(ord1, ord2);
      if (comp != 0) return comp;
    }
    return 0;
  }
}

class CoordinateSequences {
  static void reverse(CoordinateSequence seq) {
    if (seq.size() <= 1) return;

    int last = seq.size() - 1;
    int mid = last ~/ 2;
    for (int i = 0; i <= mid; i++) {
      swap(seq, i, last - i);
    }
  }

  static void swap(CoordinateSequence seq, int i, int j) {
    if (i == j) return;

    for (int dim = 0; dim < seq.getDimension(); dim++) {
      double tmp = seq.getOrdinate(i, dim);
      seq.setOrdinate(i, dim, seq.getOrdinate(j, dim));
      seq.setOrdinate(j, dim, tmp);
    }
  }

  static void copy(CoordinateSequence src, int srcPos, CoordinateSequence dest, int destPos, int length) {
    for (int i = 0; i < length; i++) {
      copyCoord(src, srcPos + i, dest, destPos + i);
    }
  }

  static void copyCoord(CoordinateSequence src, int srcPos, CoordinateSequence dest, int destPos) {
    int minDim = Math.min(src.getDimension(), dest.getDimension()).toInt();
    for (int dim = 0; dim < minDim; dim++) {
      dest.setOrdinate(destPos, dim, src.getOrdinate(srcPos, dim));
    }
  }

  static bool isRing(CoordinateSequence seq) {
    int n = seq.size();
    if (n == 0) return true;

    if (n <= 3) return false;

    return (seq.getOrdinate(0, CoordinateSequence.X) == seq.getOrdinate(n - 1, CoordinateSequence.X)) &&
        (seq.getOrdinate(0, CoordinateSequence.Y) == seq.getOrdinate(n - 1, CoordinateSequence.Y));
  }

  static CoordinateSequence ensureValidRing(CoordinateSequenceFactory fact, CoordinateSequence seq) {
    int n = seq.size();
    if (n == 0) return seq;

    if (n <= 3) return createClosedRing(fact, seq, 4);

    bool isClosed =
        (seq.getOrdinate(0, CoordinateSequence.X) == seq.getOrdinate(n - 1, CoordinateSequence.X)) &&
        (seq.getOrdinate(0, CoordinateSequence.Y) == seq.getOrdinate(n - 1, CoordinateSequence.Y));
    if (isClosed) return seq;

    return createClosedRing(fact, seq, n + 1);
  }

  static CoordinateSequence createClosedRing(CoordinateSequenceFactory fact, CoordinateSequence seq, int size) {
    CoordinateSequence newseq = fact.create3(size, seq.getDimension());
    int n = seq.size();
    copy(seq, 0, newseq, 0, n);
    for (int i = n; i < size; i++) {
      copy(seq, 0, newseq, i, 1);
    }

    return newseq;
  }

  static CoordinateSequence extend(CoordinateSequenceFactory fact, CoordinateSequence seq, int size) {
    CoordinateSequence newseq = fact.create3(size, seq.getDimension());
    int n = seq.size();
    copy(seq, 0, newseq, 0, n);
    if (n > 0) {
      for (int i = n; i < size; i++) {
        copy(seq, n - 1, newseq, i, 1);
      }
    }
    return newseq;
  }

  static bool isEqual(CoordinateSequence cs1, CoordinateSequence cs2) {
    int cs1Size = cs1.size();
    int cs2Size = cs2.size();
    if (cs1Size != cs2Size) return false;

    int dim = Math.min(cs1.getDimension(), cs2.getDimension()).toInt();
    for (int i = 0; i < cs1Size; i++) {
      for (int d = 0; d < dim; d++) {
        double v1 = cs1.getOrdinate(i, d);
        double v2 = cs2.getOrdinate(i, d);
        if (cs1.getOrdinate(i, d) == cs2.getOrdinate(i, d)) {
          continue;
        } else if (Double.isNaN(v1) && Double.isNaN(v2)) {
          continue;
        } else {
          return false;
        }
      }
    }
    return true;
  }

  static Coordinate? minCoordinate(CoordinateSequence seq) {
    Coordinate? minCoord;
    for (int i = 0; i < seq.size(); i++) {
      Coordinate testCoord = seq.getCoordinate(i);
      if ((minCoord == null) || (minCoord.compareTo(testCoord) > 0)) {
        minCoord = testCoord;
      }
    }
    return minCoord;
  }

  static int minCoordinateIndex(CoordinateSequence seq) {
    return minCoordinateIndex2(seq, 0, seq.size() - 1);
  }

  static int minCoordinateIndex2(CoordinateSequence seq, int from, int to) {
    int minCoordIndex = -1;
    Coordinate? minCoord;
    for (int i = from; i <= to; i++) {
      Coordinate testCoord = seq.getCoordinate(i);
      if ((minCoord == null) || (minCoord.compareTo(testCoord) > 0)) {
        minCoord = testCoord;
        minCoordIndex = i;
      }
    }
    return minCoordIndex;
  }

  static void scroll(CoordinateSequence seq, Coordinate firstCoordinate) {
    int i = indexOf(firstCoordinate, seq);
    if (i <= 0) return;
    scroll2(seq, i);
  }

  static void scroll2(CoordinateSequence seq, int indexOfFirstCoordinate) {
    scroll3(seq, indexOfFirstCoordinate, CoordinateSequences.isRing(seq));
  }

  static void scroll3(CoordinateSequence seq, int indexOfFirstCoordinate, bool ensureRing) {
    int i = indexOfFirstCoordinate;
    if (i <= 0) return;

    CoordinateSequence copy = seq.copy();
    int last = (ensureRing) ? seq.size() - 1 : seq.size();
    for (int j = 0; j < last; j++) {
      for (int k = 0; k < seq.getDimension(); k++) {
        seq.setOrdinate(j, k, copy.getOrdinate((indexOfFirstCoordinate + j) % last, k));
      }
    }
    if (ensureRing) {
      for (int k = 0; k < seq.getDimension(); k++) {
        seq.setOrdinate(last, k, seq.getOrdinate(0, k));
      }
    }
  }

  static int indexOf(Coordinate coordinate, CoordinateSequence seq) {
    for (int i = 0; i < seq.size(); i++) {
      if ((coordinate.x == seq.getOrdinate(i, CoordinateSequence.X)) &&
          (coordinate.y == seq.getOrdinate(i, CoordinateSequence.Y))) {
        return i;
      }
    }
    return -1;
  }
}

//impl
class CoordinateArraySequence extends CoordinateSequence {
  int _dimension = 3;

  int _measures = 0;

  late Array<Coordinate> _coordinates;

  CoordinateArraySequence(Array<Coordinate>? coordinates)
    : this.of2(coordinates, CoordinateArrays.dimension(coordinates), CoordinateArrays.measures(coordinates));

  CoordinateArraySequence.of(Array<Coordinate>? coordinates, int dimension)
    : this.of2(coordinates, dimension, CoordinateArrays.measures(coordinates));

  CoordinateArraySequence.of2(Array<Coordinate>? coordinates, this._dimension, this._measures) {
    if (coordinates == null) {
      _coordinates = Array();
    } else {
      _coordinates = coordinates;
    }
  }

  CoordinateArraySequence.of3(int size) {
    _coordinates = Array(size);
    for (int i = 0; i < size; i++) {
      _coordinates[i] = Coordinate();
    }
  }

  CoordinateArraySequence.of4(int size, int dimension) {
    _coordinates = Array(size);
    _dimension = dimension;
    for (int i = 0; i < size; i++) {
      _coordinates[i] = Coordinates.create(dimension);
    }
  }

  CoordinateArraySequence.of5(int size, this._dimension, this._measures) {
    _coordinates = Array(size);
    for (int i = 0; i < size; i++) {
      _coordinates[i] = createCoordinate();
    }
  }

  CoordinateArraySequence.of6(CoordinateSequence? coordSeq) {
    if (coordSeq == null) {
      _coordinates = Array();
      return;
    }
    _dimension = coordSeq.getDimension();
    _measures = coordSeq.getMeasures();
    _coordinates = Array(coordSeq.size());
    for (int i = 0; i < _coordinates.length; i++) {
      _coordinates[i] = coordSeq.getCoordinateCopy(i);
    }
  }

  @override
  int getDimension() {
    return _dimension;
  }

  @override
  int getMeasures() {
    return _measures;
  }

  @override
  Coordinate getCoordinate(int i) {
    return _coordinates[i];
  }

  @override
  Coordinate getCoordinateCopy(int i) {
    Coordinate copy = createCoordinate();
    copy.setCoordinate(_coordinates[i]);
    return copy;
  }

  @override
  void getCoordinate2(int index, Coordinate coord) {
    coord.setCoordinate(_coordinates[index]);
  }

  @override
  double getX(int index) {
    return _coordinates[index].x;
  }

  @override
  double getY(int index) {
    return _coordinates[index].y;
  }

  @override
  double getZ(int index) {
    if (hasZ()) {
      return _coordinates[index].getZ();
    } else {
      return double.nan;
    }
  }

  @override
  double getM(int index) {
    if (hasM()) {
      return _coordinates[index].getM();
    } else {
      return double.nan;
    }
  }

  @override
  double getOrdinate(int index, int ordinateIndex) {
    switch (ordinateIndex) {
      case CoordinateSequence.X:
        return _coordinates[index].x;
      case CoordinateSequence.Y:
        return _coordinates[index].y;
      default:
        return _coordinates[index].getOrdinate(ordinateIndex);
    }
  }

  @override
  CoordinateArraySequence clone() {
    return copy();
  }

  @override
  CoordinateArraySequence copy() {
    Array<Coordinate> cloneCoordinates = Array(size());
    for (int i = 0; i < _coordinates.length; i++) {
      Coordinate duplicate = createCoordinate();
      duplicate.setCoordinate(_coordinates[i]);
      cloneCoordinates[i] = duplicate;
    }
    return CoordinateArraySequence.of2(cloneCoordinates, _dimension, _measures);
  }

  @override
  int size() {
    return _coordinates.length;
  }

  @override
  void setOrdinate(int index, int ordinateIndex, double value) {
    switch (ordinateIndex) {
      case CoordinateSequence.X:
        _coordinates[index].x = value;
        break;
      case CoordinateSequence.Y:
        _coordinates[index].y = value;
        break;
      default:
        _coordinates[index].setOrdinate(ordinateIndex, value);
    }
  }

  @override
  Array<Coordinate> toCoordinateArray() {
    return _coordinates;
  }

  @override
  Envelope expandEnvelope(Envelope env) {
    for (int i = 0; i < _coordinates.length; i++) {
      env.expandToInclude(_coordinates[i]);
    }
    return env;
  }

  @override
  String toString() {
    if (_coordinates.length > 0) {
      StringBuffer strBuilder = StringBuffer();
      strBuilder.write('(');
      strBuilder.write(_coordinates[0]);
      for (int i = 1; i < _coordinates.length; i++) {
        strBuilder.write(", ");
        strBuilder.write(_coordinates[i]);
      }
      strBuilder.write(')');
      return strBuilder.toString();
    } else {
      return "()";
    }
  }
}

final class CoordinateArraySequenceFactory implements CoordinateSequenceFactory {
  static final CoordinateArraySequenceFactory _instanceObject = CoordinateArraySequenceFactory();

  Object readResolve() {
    return CoordinateArraySequenceFactory.instance();
  }

  static CoordinateArraySequenceFactory instance() {
    return _instanceObject;
  }

  @override
  CoordinateSequence create(Array<Coordinate>? coordinates) {
    return CoordinateArraySequence(coordinates);
  }

  @override
  CoordinateSequence create2(CoordinateSequence coordSeq) {
    return CoordinateArraySequence.of6(coordSeq);
  }

  @override
  CoordinateSequence create3(int size, int dimension) {
    if (dimension > 3) dimension = 3;

    if (dimension < 2) dimension = 2;

    return CoordinateArraySequence.of4(size, dimension);
  }

  @override
  CoordinateSequence create4(int size, int dimension, int measures) {
    int spatial = dimension - measures;
    if (measures > 1) {
      measures = 1;
    }
    if (spatial > 3) {
      spatial = 3;
    }
    if (spatial < 2) spatial = 2;

    return CoordinateArraySequence.of5(size, spatial + measures, measures);
  }
}

abstract class PackedCoordinateSequence extends CoordinateSequence {
  int dimension;

  int measures;

  PackedCoordinateSequence(this.dimension, this.measures) {
    if ((dimension - measures) < 2) {
      throw ("Must have at least 2 spatial dimensions");
    }
  }

  Array<Coordinate>? coordRef;

  @override
  int getDimension() {
    return dimension;
  }

  @override
  int getMeasures() {
    return measures;
  }

  @override
  Coordinate getCoordinate(int i) {
    Array<Coordinate>? coords = getCachedCoords();
    if (coords != null) {
      return coords[i];
    } else {
      return getCoordinateInternal(i);
    }
  }

  @override
  Coordinate getCoordinateCopy(int i) {
    return getCoordinateInternal(i);
  }

  @override
  void getCoordinate2(int i, Coordinate coord) {
    coord.x = getOrdinate(i, 0);
    coord.y = getOrdinate(i, 1);
    if (hasZ()) {
      coord.setZ(getZ(i));
    }
    if (hasM()) {
      coord.setM(getM(i));
    }
  }

  @override
  Array<Coordinate> toCoordinateArray() {
    Array<Coordinate>? coords = getCachedCoords();
    if (coords != null) {
      return coords;
    }

    coords = Array(size());
    for (int i = 0; i < coords.length; i++) {
      coords[i] = getCoordinateInternal(i);
    }
    coordRef = coords;
    return coords;
  }

  Array<Coordinate>? getCachedCoords() {
    if (coordRef != null) {
      Array<Coordinate> coords = coordRef!;
      return coords;
    } else {
      return null;
    }
  }

  @override
  double getX(int index) {
    return getOrdinate(index, 0);
  }

  @override
  double getY(int index) {
    return getOrdinate(index, 1);
  }

  @override
  double getOrdinate(int index, int ordinateIndex);

  void setX(int index, double value) {
    coordRef = null;
    setOrdinate(index, 0, value);
  }

  void setY(int index, double value) {
    coordRef = null;
    setOrdinate(index, 1, value);
  }

  PackedCoordinateSequence readResolve() {
    coordRef = null;
    return this;
  }

  Coordinate getCoordinateInternal(int index);

  @override
  PackedCoordinateSequence clone();

  @override
  PackedCoordinateSequence copy();

  @override
  void setOrdinate(int index, int ordinate, double value);
}

class PDouble extends PackedCoordinateSequence {
  late Array<double> coords;

  PDouble(this.coords, int dimension, int measures) : super(dimension, measures) {
    if ((coords.length % dimension) != 0) {
      throw IllegalArgumentException(
        "Packed array does not contain "
        "an integral number of coordinates",
      );
    }
  }

  PDouble.of(Array<double> coords, int dimension, int measures) : super(dimension, measures) {
    this.coords = coords.copy();
  }

  PDouble.of2(Array<Coordinate>? coordinates, int dimension)
    : this.of3(coordinates, dimension, Math.max(0, dimension - 3).toInt());

  PDouble.of3(Array<Coordinate>? coordinates, int dimension, int measures) : super(dimension, measures) {
    coordinates ??= Array();
    coords = Array(coordinates.length * this.dimension);
    for (int i = 0; i < coordinates.length; i++) {
      int offset = i * dimension;
      coords[offset] = coordinates[i].x;
      coords[offset + 1] = coordinates[i].y;
      if (dimension >= 3) coords[offset + 2] = coordinates[i].getOrdinate(2);
      if (dimension >= 4) coords[offset + 3] = coordinates[i].getOrdinate(3);
    }
  }

  PDouble.of4(Array<Coordinate>? coordinates) : this.of3(coordinates, 3, 0);

  PDouble.of5(int size, int dimension, int measures) : super(dimension, measures) {
    coords = Array(size * this.dimension);
  }

  @override
  Coordinate getCoordinateInternal(int i) {
    double x = coords[i * dimension];
    double y = coords[(i * dimension) + 1];
    if ((dimension == 2) && (measures == 0)) {
      return CoordinateXY(x, y);
    }
    if ((dimension == 3) && (measures == 0)) {
      double z = coords[(i * dimension) + 2];
      return Coordinate(x, y, z);
    }
    if ((dimension == 3) && (measures == 1)) {
      double m = coords[(i * dimension) + 2];
      return CoordinateXYM(x, y, m);
    }
    if (dimension == 4) {
      double z = coords[(i * dimension) + 2];
      double m = coords[(i * dimension) + 3];
      return CoordinateXYZM(x, y, z, m);
    }
    return Coordinate(x, y);
  }

  Array<double> getRawCoordinates() {
    return coords;
  }

  @override
  int size() {
    return coords.length ~/ dimension;
  }

  @override
  PDouble clone() {
    return copy();
  }

  @override
  PDouble copy() {
    return PDouble.of(coords.copy(), dimension, measures);
  }

  @override
  double getOrdinate(int index, int ordinate) {
    return coords[(index * dimension) + ordinate];
  }

  @override
  void setOrdinate(int index, int ordinate, double value) {
    coordRef = null;
    coords[(index * dimension) + ordinate] = value;
  }

  @override
  Envelope expandEnvelope(Envelope env) {
    for (int i = 0; i < coords.length; i += dimension) {
      if ((i + 1) < coords.length) {
        env.expandToInclude2(coords[i], coords[i + 1]);
      }
    }
    return env;
  }
}

class PackedCoordinateSequenceFactory implements CoordinateSequenceFactory {
  static const int DOUBLE = 0;
  static final DOUBLE_FACTORY = PackedCoordinateSequenceFactory();
  static const int _defaultMeasures = 0;
  static const int _defaultDimension = 3;

  final int _type = DOUBLE;

  int getType() {
    return _type;
  }

  @override
  CoordinateSequence create(Array<Coordinate?>? coordinates) {
    int dimension = _defaultDimension;
    int measures = _defaultMeasures;
    if (((coordinates != null) && (coordinates.isNotEmpty)) && (coordinates[0] != null)) {
      Coordinate first = coordinates[0]!;
      dimension = Coordinates.dimension(first);
      measures = Coordinates.measures(first);
    }
    return PDouble.of3(coordinates!.asArray(), dimension, measures);
  }

  @override
  CoordinateSequence create2(CoordinateSequence coordSeq) {
    int dimension = coordSeq.getDimension();
    int measures = coordSeq.getMeasures();
    return PDouble.of3(coordSeq.toCoordinateArray(), dimension, measures);
  }

  @override
  CoordinateSequence create3(int size, int dimension) {
    return PDouble.of5(size, dimension, Math.max(_defaultMeasures, dimension - 3).toInt());
  }

  @override
  CoordinateSequence create4(int size, int dimension, int measures) {
    return PDouble.of5(size, dimension, measures);
  }

  CoordinateSequence create5(Array<double> packedCoordinates, int dimension, int measures) {
    return PDouble.of(packedCoordinates, dimension, measures);
  }

  CoordinateSequence create6(Array<double> packedCoordinates, int dimension) {
    return create5(packedCoordinates, dimension, _defaultMeasures);
  }
}
