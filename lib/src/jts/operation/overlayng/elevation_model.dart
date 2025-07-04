import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/math/math.dart';

class ElevationModel {
  static const int _kDefaultCellNum = 3;

  static ElevationModel create(Geometry geom1, Geometry? geom2) {
    Envelope extent = geom1.getEnvelopeInternal().copy();
    if (geom2 != null) {
      extent.expandToInclude(geom2.getEnvelopeInternal());
    }
    ElevationModel model = ElevationModel(extent, _kDefaultCellNum, _kDefaultCellNum);
    model.add(geom1);

    if (geom2 != null) {
      model.add(geom2);
    }

    return model;
  }

  final Envelope _extent;

  late int _numCellX;

  late int _numCellY;

  double _cellSizeX = 0;

  double _cellSizeY = 0;

  late Array<Array<ElevationCell>> _cells;

  bool _isInitialized = false;

  bool _hasZValue = false;

  double _averageZ = double.nan;

  ElevationModel(this._extent, int numCellX, int numCellY) {
    _cellSizeX = _extent.width / numCellX;
    _cellSizeY = _extent.height / numCellY;
    _numCellX = numCellX;
    _numCellY = numCellY;
    if (_cellSizeX <= 0.0) {
      _numCellX = 1;
    }
    if (_cellSizeY <= 0.0) {
      _numCellY = 1;
    }
    _cells = Array.matrix2(numCellX, numCellY);
  }

  void add(Geometry geom) {
    geom.apply2(_CoordinateSequenceFilter(this));
  }

  void add2(double x, double y, double z) {
    if (Double.isNaN(z)) {
      return;
    }

    _hasZValue = true;
    final cell = getCell(x, y, true);
    cell?.add(z);
  }

  void init() {
    _isInitialized = true;
    int numCells = 0;
    double sumZ = 0.0;
    for (int i = 0; i < _cells.length; i++) {
      for (int j = 0; j < _cells[0].length; j++) {
        ElevationCell? cell = _cells[i].get(j);
        if (cell != null) {
          cell.compute();
          numCells++;
          sumZ += cell.getZ();
        }
      }
    }
    _averageZ = double.nan;
    if (numCells > 0) {
      _averageZ = sumZ / numCells;
    }
  }

  double getZ(double x, double y) {
    if (!_isInitialized) {
      init();
    }

    final cell = getCell(x, y, false);
    if (cell == null) {
      return _averageZ;
    }

    return cell.getZ();
  }

  void populateZ(Geometry geom) {
    if (!_hasZValue) {
      return;
    }

    if (!_isInitialized) {
      init();
    }

    geom.apply2(_CoordinateSequenceFilter2(this));
  }

  ElevationCell? getCell(double x, double y, bool isCreateIfMissing) {
    int ix = 0;
    if (_numCellX > 1) {
      ix = (x - _extent.minX) ~/ _cellSizeX;
      ix = MathUtil.clamp(ix, 0, _numCellX - 1);
    }
    int iy = 0;
    if (_numCellY > 1) {
      iy = (y - _extent.minY) ~/ _cellSizeY;
      iy = MathUtil.clamp(iy, 0, _numCellY - 1);
    }
    var cell = _cells[ix].get(iy);
    if (isCreateIfMissing && (cell == null)) {
      cell = ElevationCell();
      _cells[ix][iy] = cell;
    }
    return cell;
  }
}

class ElevationCell {
  int _numZ = 0;

  double _sumZ = 0.0;

  double _avgZ = 0;

  void add(double z) {
    _numZ++;
    _sumZ += z;
  }

  void compute() {
    _avgZ = double.nan;
    if (_numZ > 0) {
      _avgZ = _sumZ / _numZ;
    }
  }

  double getZ() {
    return _avgZ;
  }
}

class _CoordinateSequenceFilter implements CoordinateSequenceFilter {
  final ElevationModel parent;
  bool hasZ = true;

  _CoordinateSequenceFilter(this.parent);

  @override
  void filter(CoordinateSequence seq, int i) {
    if (!seq.hasZ()) {
      hasZ = false;
      return;
    }
    double z = seq.getOrdinate(i, Coordinate.kZ);
    parent.add2(seq.getOrdinate(i, Coordinate.kX), seq.getOrdinate(i, Coordinate.kY), z);
  }

  @override
  bool isDone() {
    return !hasZ;
  }

  @override
  bool isGeometryChanged() => false;
}

class _CoordinateSequenceFilter2 implements CoordinateSequenceFilter {
  final ElevationModel parent;

  _CoordinateSequenceFilter2(this.parent);

  bool _isDone = false;

  @override
  void filter(CoordinateSequence seq, int i) {
    if (!seq.hasZ()) {
      _isDone = true;
      return;
    }
    if (Double.isNaN(seq.getZ(i))) {
      double z = parent.getZ(seq.getOrdinate(i, Coordinate.kX), seq.getOrdinate(i, Coordinate.kY));
      seq.setOrdinate(i, Coordinate.kZ, z);
    }
  }

  @override
  bool isDone() {
    return _isDone;
  }

  @override
  bool isGeometryChanged() => false;
}
