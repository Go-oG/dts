import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/intersection_matrix.dart';
import 'package:dts/src/jts/geom/location.dart';

import 'impredicate.dart';

class IMPatternMatcher extends IMPredicate {
  final String _imPattern;
  late IntersectionMatrix _patternMatrix;

  IMPatternMatcher(this._imPattern) {
    _patternMatrix = IntersectionMatrix.of(_imPattern);
  }

  @override
  String name() {
    return "IMPattern";
  }

  @override
  void init2(Envelope envA, Envelope envB) {
    super.init(dimA, dimB);
    bool requiresInteraction = requireInteraction2(_patternMatrix);
    bool isDisjoint = envA.disjoint(envB);
    setValueIf(false, requiresInteraction && isDisjoint);
  }

  @override
  bool requireInteraction() {
    return requireInteraction2(_patternMatrix);
  }

  static bool requireInteraction2(IntersectionMatrix im) {
    bool requiresInteraction =
        ((isInteraction(im.get(Location.interior, Location.interior)) ||
                isInteraction(im.get(Location.interior, Location.boundary))) ||
            isInteraction(im.get(Location.boundary, Location.interior))) ||
        isInteraction(im.get(Location.boundary, Location.boundary));
    return requiresInteraction;
  }

  static bool isInteraction(int imDim) {
    return (imDim == Dimension.TRUE) || (imDim >= Dimension.P);
  }

  @override
  bool isDetermined() {
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int patternEntry = _patternMatrix.get(i, j);
        if (patternEntry == Dimension.DONTCARE) {
          continue;
        }

        int matrixVal = getDimension(i, j);
        if (patternEntry == Dimension.TRUE) {
          if (matrixVal < 0) {
            return false;
          }
        } else if (matrixVal > patternEntry) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  bool valueIM() {
    bool val = intMatrix.matches2(_imPattern);
    return val;
  }
}
