import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/location.dart';

import 'edge_source_info.dart';
import 'overlay_label.dart';

class OEdge {
  static bool isCollapsed(Array<Coordinate> pts) {
    if (pts.length < 2) return true;

    if (pts[0].equals2D(pts[1])) return true;

    if (pts.length > 2) {
      if (pts[pts.length - 1].equals2D(pts[pts.length - 2])) return true;
    }
    return false;
  }

  Array<Coordinate> pts;

  int _aDim = OverlayLabel.DIM_UNKNOWN;

  int _aDepthDelta = 0;

  bool _aIsHole = false;

  int _bDim = OverlayLabel.DIM_UNKNOWN;

  int _bDepthDelta = 0;

  bool _bIsHole = false;

  OEdge(this.pts, EdgeSourceInfo info) {
    copyInfo(info);
  }

  Array<Coordinate> getCoordinates() {
    return pts;
  }

  Coordinate getCoordinate(int index) {
    return pts[index];
  }

  int size() {
    return pts.length;
  }

  bool direction() {
    Array<Coordinate> pts = getCoordinates();
    if (pts.length < 2) {
      throw ("Edge must have >= 2 points");
    }
    Coordinate p0 = pts[0];
    Coordinate p1 = pts[1];
    Coordinate pn0 = pts[pts.length - 1];
    Coordinate pn1 = pts[pts.length - 2];
    int cmp = 0;
    int cmp0 = p0.compareTo(pn0);
    if (cmp0 != 0) cmp = cmp0;

    if (cmp == 0) {
      int cmp1 = p1.compareTo(pn1);
      if (cmp1 != 0) cmp = cmp1;
    }
    if (cmp == 0) {
      throw ("Edge direction cannot be determined because endpoints are equal");
    }
    return cmp == (-1);
  }

  bool relativeDirection(OEdge edge2) {
    if (!getCoordinate(0).equals2D(edge2.getCoordinate(0))) return false;

    if (!getCoordinate(1).equals2D(edge2.getCoordinate(1))) return false;

    return true;
  }

  OverlayLabel createLabel() {
    OverlayLabel lbl = OverlayLabel.empty();
    initLabel(lbl, 0, _aDim, _aDepthDelta, _aIsHole);
    initLabel(lbl, 1, _bDim, _bDepthDelta, _bIsHole);
    return lbl;
  }

  static void initLabel(OverlayLabel lbl, int geomIndex, int dim, int depthDelta, bool isHole) {
    int dimLabel = labelDim(dim, depthDelta);
    switch (dimLabel) {
      case OverlayLabel.DIM_NOT_PART:
        lbl.initNotPart(geomIndex);
        break;
      case OverlayLabel.DIM_BOUNDARY:
        lbl.initBoundary(geomIndex, locationLeft(depthDelta), locationRight(depthDelta), isHole);
        break;
      case OverlayLabel.DIM_COLLAPSE:
        lbl.initCollapse(geomIndex, isHole);
        break;
      case OverlayLabel.DIM_LINE:
        lbl.initLine(geomIndex);
        break;
    }
  }

  static int labelDim(int dim, int depthDelta) {
    if (dim == Dimension.False) return OverlayLabel.DIM_NOT_PART;

    if (dim == Dimension.L) return OverlayLabel.DIM_LINE;

    bool isCollapse = depthDelta == 0;
    if (isCollapse) return OverlayLabel.DIM_COLLAPSE;

    return OverlayLabel.DIM_BOUNDARY;
  }

  bool isShell(int geomIndex) {
    if (geomIndex == 0) {
      return (_aDim == OverlayLabel.DIM_BOUNDARY) && (!_aIsHole);
    }
    return (_bDim == OverlayLabel.DIM_BOUNDARY) && (!_bIsHole);
  }

  static int locationRight(int depthDelta) {
    int delSignV = delSign(depthDelta);
    switch (delSignV) {
      case 0:
        return OverlayLabel.LOC_UNKNOWN;
      case 1:
        return Location.interior;
      case -1:
        return Location.exterior;
      default:
        break;
    }
    return OverlayLabel.LOC_UNKNOWN;
  }

  static int locationLeft(int depthDelta) {
    int delSignV = delSign(depthDelta);
    switch (delSignV) {
      case 0:
        return OverlayLabel.LOC_UNKNOWN;
      case 1:
        return Location.exterior;
      case -1:
        return Location.interior;
      default:
        break;
    }
    return OverlayLabel.LOC_UNKNOWN;
  }

  static int delSign(int depthDel) {
    if (depthDel > 0) return 1;

    if (depthDel < 0) return -1;

    return 0;
  }

  void copyInfo(EdgeSourceInfo info) {
    if (info.getIndex() == 0) {
      _aDim = info.getDimension();
      _aIsHole = info.isHole();
      _aDepthDelta = info.getDepthDelta();
    } else {
      _bDim = info.getDimension();
      _bIsHole = info.isHole();
      _bDepthDelta = info.getDepthDelta();
    }
  }

  void merge(OEdge edge) {
    _aIsHole = isHoleMerged(0, this, edge);
    _bIsHole = isHoleMerged(1, this, edge);
    if (edge._aDim > _aDim) _aDim = edge._aDim;

    if (edge._bDim > _bDim) _bDim = edge._bDim;

    bool relDir = relativeDirection(edge);
    int flipFactor = (relDir) ? 1 : -1;
    _aDepthDelta += flipFactor * edge._aDepthDelta;
    _bDepthDelta += flipFactor * edge._bDepthDelta;
  }

  static bool isHoleMerged(int geomIndex, OEdge edge1, OEdge edge2) {
    bool isShell1 = edge1.isShell(geomIndex);
    bool isShell2 = edge2.isShell(geomIndex);
    bool isShellMerged = isShell1 || isShell2;
    return !isShellMerged;
  }

  static String infoString(int index, int dim, bool isHole, int depthDelta) {
    return (((index == 0 ? "A:" : "B:") + OverlayLabel.dimensionSymbol(dim)) +
            ringRoleSymbol(dim, isHole)) +
        depthDelta.toString();
  }

  static String ringRoleSymbol(int dim, bool isHole) {
    if (hasAreaParent(dim)) {
      return OverlayLabel.ringRoleSymbol(isHole);
    }
    return "";
  }

  static bool hasAreaParent(int dim) {
    return (dim == OverlayLabel.DIM_BOUNDARY) || (dim == OverlayLabel.DIM_COLLAPSE);
  }
}
