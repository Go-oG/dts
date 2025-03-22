import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/intersection_matrix.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'label.dart';

abstract class GraphComponent {
  Label? label;

  bool isInResult = false;

  bool _isCovered = false;

  bool _isCoveredSet = false;

  bool isVisited = false;

  GraphComponent([this.label]);

  Label? getLabel() {
    return label;
  }

  void setLabel(Label? label) {
    this.label = label;
  }

  void setCovered(bool isCovered) {
    _isCovered = isCovered;
    _isCoveredSet = true;
  }

  bool isCovered() {
    return _isCovered;
  }

  bool isCoveredSet() {
    return _isCoveredSet;
  }

  Coordinate? getCoordinate();

  void computeIM(IntersectionMatrix im);

  bool isIsolated();

  void updateIM(IntersectionMatrix im) {
    Assert.isTrue2(label!.getGeometryCount() >= 2, "found partial label");
    computeIM(im);
  }
}
