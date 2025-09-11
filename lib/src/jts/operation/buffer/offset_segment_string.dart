import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/precision_model.dart';

class OffsetSegmentString {
  final List<Coordinate> _ptList = [];

  late PrecisionModel precisionModel;

  double _minimimVertexDistance = 0.0;

  void setPrecisionModel(PrecisionModel precisionModel) {
    this.precisionModel = precisionModel;
  }

  void setMinimumVertexDistance(double minVertexDistance) {
    _minimimVertexDistance = minVertexDistance;
  }

  void addPt(Coordinate pt) {
    Coordinate bufPt = Coordinate.of(pt);
    precisionModel.makePrecise(bufPt);
    if (isRedundant(bufPt)) {
      return;
    }

    _ptList.add(bufPt);
  }

  void addPts2(List<Coordinate> pt, bool isForward) {
    if (isForward) {
      for (int i = 0; i < pt.length; i++) {
        addPt(pt[i]);
      }
    } else {
      for (int i = pt.length - 1; i >= 0; i--) {
        addPt(pt[i]);
      }
    }
  }

  bool isRedundant(Coordinate pt) {
    if (_ptList.size < 1) return false;

    Coordinate lastPt = _ptList.last;
    double ptDist = pt.distance(lastPt);
    if (ptDist < _minimimVertexDistance) {
      return true;
    }

    return false;
  }

  void closeRing() {
    if (_ptList.size < 1) return;

    Coordinate startPt = Coordinate.of(_ptList.first);
    Coordinate lastPt = _ptList.last;
    if (startPt == lastPt) {
      return;
    }

    _ptList.add(startPt);
  }

  void reverse() {}

  List<Coordinate> getCoordinates() => _ptList;

  @override
  String toString() {
    GeometryFactory fact = GeometryFactory();
    LineString line = fact.createLineString2(getCoordinates());
    return line.toString();
  }
}
