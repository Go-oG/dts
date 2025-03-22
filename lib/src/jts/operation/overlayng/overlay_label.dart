import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/position.dart';

class OverlayLabel {
  static final String _SYM_UNKNOWN = '#';

  static final String _SYM_BOUNDARY = 'B';

  static final String _SYM_COLLAPSE = 'C';

  static final String _SYM_LINE = 'L';

  static const int DIM_UNKNOWN = -1;

  static const int DIM_NOT_PART = DIM_UNKNOWN;

  static const int DIM_LINE = 1;

  static const int DIM_BOUNDARY = 2;

  static const int DIM_COLLAPSE = 3;

  static int LOC_UNKNOWN = Location.none;

  int _aDim = DIM_NOT_PART;

  bool aIsHole = false;

  int _aLocLeft = LOC_UNKNOWN;

  int _aLocRight = LOC_UNKNOWN;

  int _aLocLine = LOC_UNKNOWN;

  int _bDim = DIM_NOT_PART;

  bool bIsHole = false;

  int _bLocLeft = LOC_UNKNOWN;

  int _bLocRight = LOC_UNKNOWN;

  int _bLocLine = LOC_UNKNOWN;

  OverlayLabel.empty();

  OverlayLabel(int index) {
    initLine(index);
  }

  OverlayLabel.of(int index, int locLeft, int locRight, bool isHole) {
    initBoundary(index, locLeft, locRight, isHole);
  }

  OverlayLabel.from(OverlayLabel lbl) {
    _aLocLeft = lbl._aLocLeft;
    _aLocRight = lbl._aLocRight;
    _aLocLine = lbl._aLocLine;
    _aDim = lbl._aDim;
    aIsHole = lbl.aIsHole;
    _bLocLeft = lbl._bLocLeft;
    _bLocRight = lbl._bLocRight;
    _bLocLine = lbl._bLocLine;
    _bDim = lbl._bDim;
    bIsHole = lbl.bIsHole;
  }

  int dimension(int index) {
    if (index == 0) return _aDim;

    return _bDim;
  }

  void initBoundary(int index, int locLeft, int locRight, bool isHole) {
    if (index == 0) {
      _aDim = DIM_BOUNDARY;
      aIsHole = isHole;
      _aLocLeft = locLeft;
      _aLocRight = locRight;
      _aLocLine = Location.interior;
    } else {
      _bDim = DIM_BOUNDARY;
      bIsHole = isHole;
      _bLocLeft = locLeft;
      _bLocRight = locRight;
      _bLocLine = Location.interior;
    }
  }

  void initCollapse(int index, bool isHole) {
    if (index == 0) {
      _aDim = DIM_COLLAPSE;
      aIsHole = isHole;
    } else {
      _bDim = DIM_COLLAPSE;
      bIsHole = isHole;
    }
  }

  void initLine(int index) {
    if (index == 0) {
      _aDim = DIM_LINE;
      _aLocLine = LOC_UNKNOWN;
    } else {
      _bDim = DIM_LINE;
      _bLocLine = LOC_UNKNOWN;
    }
  }

  void initNotPart(int index) {
    if (index == 0) {
      _aDim = DIM_NOT_PART;
    } else {
      _bDim = DIM_NOT_PART;
    }
  }

  void setLocationLine(int index, int loc) {
    if (index == 0) {
      _aLocLine = loc;
    } else {
      _bLocLine = loc;
    }
  }

  void setLocationAll(int index, int loc) {
    if (index == 0) {
      _aLocLine = loc;
      _aLocLeft = loc;
      _aLocRight = loc;
    } else {
      _bLocLine = loc;
      _bLocLeft = loc;
      _bLocRight = loc;
    }
  }

  void setLocationCollapse(int index) {
    int loc = (isHole(index)) ? Location.interior : Location.exterior;
    if (index == 0) {
      _aLocLine = loc;
    } else {
      _bLocLine = loc;
    }
  }

  bool isLine() {
    return (_aDim == DIM_LINE) || (_bDim == DIM_LINE);
  }

  bool isLine2(int index) {
    if (index == 0) {
      return _aDim == DIM_LINE;
    }
    return _bDim == DIM_LINE;
  }

  bool isLinear(int index) {
    if (index == 0) {
      return (_aDim == DIM_LINE) || (_aDim == DIM_COLLAPSE);
    }
    return (_bDim == DIM_LINE) || (_bDim == DIM_COLLAPSE);
  }

  bool isKnown(int index) {
    if (index == 0) {
      return _aDim != DIM_UNKNOWN;
    }
    return _bDim != DIM_UNKNOWN;
  }

  bool isNotPart(int index) {
    if (index == 0) {
      return _aDim == DIM_NOT_PART;
    }
    return _bDim == DIM_NOT_PART;
  }

  bool isBoundaryEither() {
    return (_aDim == DIM_BOUNDARY) || (_bDim == DIM_BOUNDARY);
  }

  bool isBoundaryBoth() {
    return (_aDim == DIM_BOUNDARY) && (_bDim == DIM_BOUNDARY);
  }

  bool isBoundaryCollapse() {
    if (isLine()) return false;

    return !isBoundaryBoth();
  }

  bool isBoundaryTouch() {
    return isBoundaryBoth() && (getLocation2(0, Position.right, true) != getLocation2(1, Position.right, true));
  }

  bool isBoundary(int index) {
    if (index == 0) {
      return _aDim == DIM_BOUNDARY;
    }
    return _bDim == DIM_BOUNDARY;
  }

  bool isBoundarySingleton() {
    if ((_aDim == DIM_BOUNDARY) && (_bDim == DIM_NOT_PART)) return true;

    if ((_bDim == DIM_BOUNDARY) && (_aDim == DIM_NOT_PART)) return true;

    return false;
  }

  bool isLineLocationUnknown(int index) {
    if (index == 0) {
      return _aLocLine == LOC_UNKNOWN;
    } else {
      return _bLocLine == LOC_UNKNOWN;
    }
  }

  bool isLineInArea(int index) {
    if (index == 0) {
      return _aLocLine == Location.interior;
    }
    return _bLocLine == Location.interior;
  }

  bool isHole(int index) {
    if (index == 0) {
      return aIsHole;
    } else {
      return bIsHole;
    }
  }

  bool isCollapse(int index) {
    return dimension(index) == DIM_COLLAPSE;
  }

  bool isInteriorCollapse() {
    if ((_aDim == DIM_COLLAPSE) && (_aLocLine == Location.interior)) return true;

    if ((_bDim == DIM_COLLAPSE) && (_bLocLine == Location.interior)) return true;

    return false;
  }

  bool isCollapseAndNotPartInterior() {
    if (((_aDim == DIM_COLLAPSE) && (_bDim == DIM_NOT_PART)) && (_bLocLine == Location.interior)) return true;

    if (((_bDim == DIM_COLLAPSE) && (_aDim == DIM_NOT_PART)) && (_aLocLine == Location.interior)) return true;

    return false;
  }

  int getLineLocation(int index) {
    if (index == 0) {
      return _aLocLine;
    } else {
      return _bLocLine;
    }
  }

  bool isLineInterior(int index) {
    if (index == 0) {
      return _aLocLine == Location.interior;
    }
    return _bLocLine == Location.interior;
  }

  int getLocation2(int index, int position, bool isForward) {
    if (index == 0) {
      switch (position) {
        case Position.left:
          return isForward ? _aLocLeft : _aLocRight;
        case Position.right:
          return isForward ? _aLocRight : _aLocLeft;
        case Position.on:
          return _aLocLine;
      }
    }
    switch (position) {
      case Position.left:
        return isForward ? _bLocLeft : _bLocRight;
      case Position.right:
        return isForward ? _bLocRight : _bLocLeft;
      case Position.on:
        return _bLocLine;
    }
    return LOC_UNKNOWN;
  }

  int getLocationBoundaryOrLine(int index, int position, bool isForward) {
    if (isBoundary(index)) {
      return getLocation2(index, position, isForward);
    }
    return getLineLocation(index);
  }

  int getLocation(int index) {
    if (index == 0) {
      return _aLocLine;
    }
    return _bLocLine;
  }

  bool hasSides(int index) {
    if (index == 0) {
      return (_aLocLeft != LOC_UNKNOWN) || (_aLocRight != LOC_UNKNOWN);
    }
    return (_bLocLeft != LOC_UNKNOWN) || (_bLocRight != LOC_UNKNOWN);
  }

  OverlayLabel copy() {
    return OverlayLabel.from(this);
  }

  static String ringRoleSymbol(bool isHole) {
    return isHole ? 'h' : 's';
  }

  static String dimensionSymbol(int dim) {
    switch (dim) {
      case DIM_LINE:
        return _SYM_LINE;
      case DIM_COLLAPSE:
        return _SYM_COLLAPSE;
      case DIM_BOUNDARY:
        return _SYM_BOUNDARY;
    }
    return _SYM_UNKNOWN;
  }

  String toString2(bool isForward) {
    StringBuffer buf = StringBuffer();
    buf.write("A:");
    buf.write(_locationString(0, isForward));
    buf.write("/B:");
    buf.write(_locationString(1, isForward));
    return buf.toString();
  }

  String _locationString(int index, bool isForward) {
    StringBuffer buf = StringBuffer();
    if (isBoundary(index)) {
      buf.write(Location.toLocationSymbol(getLocation2(index, Position.left, isForward)));
      buf.write(Location.toLocationSymbol(getLocation2(index, Position.right, isForward)));
    } else {
      buf.write(Location.toLocationSymbol(index == 0 ? _aLocLine : _bLocLine));
    }
    if (isKnown(index)) buf.write(dimensionSymbol(index == 0 ? _aDim : _bDim));
    if (isCollapse(index)) {
      buf.write(ringRoleSymbol(index == 0 ? aIsHole : bIsHole));
    }
    return buf.toString();
  }
}
