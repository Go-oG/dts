import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:flutter/foundation.dart';

import 'impredicate.dart';
import 'topology_predicate.dart';

class TopologyPredicateTracer {
  static TopologyPredicate trace(TopologyPredicate pred) {
    return _PredicateTracer(pred);
  }

  TopologyPredicateTracer();
}

class _PredicateTracer implements TopologyPredicate {
  final TopologyPredicate _pred;

  _PredicateTracer(this._pred);

  @override
  String name() => _pred.name();

  @override
  bool requireSelfNoding() => _pred.requireSelfNoding();

  @override
  bool requireInteraction() => _pred.requireInteraction();

  @override
  bool requireCovers(bool isSourceA) => _pred.requireCovers(isSourceA);

  @override
  bool requireExteriorCheck(bool isSourceA) => _pred.requireExteriorCheck(isSourceA);

  @override
  void init(int dimA, int dimB) {
    _pred.init(dimA, dimB);
    checkValue("dimensions");
  }

  @override
  void init2(Envelope envA, Envelope envB) {
    _pred.init2(envA, envB);
    checkValue("envelopes");
  }

  @override
  void updateDimension(int locA, int locB, int dimension) {
    String desc = ("A:${Location.toLocationSymbol(locA)}/B:${Location.toLocationSymbol(locB)} -> $dimension");
    String ind = "";
    bool isChanged = isDimChanged(locA, locB, dimension);
    if (isChanged) {
      ind = " <<< ";
    }
    debugPrint(desc + ind);
    _pred.updateDimension(locA, locB, dimension);
    if (isChanged) {
      checkValue("IM entry");
    }
  }

  bool isDimChanged(int locA, int locB, int dimension) {
    if (_pred is IMPredicate) {
      return (_pred as IMPredicate).isDimChanged(locA, locB, dimension);
    }
    return false;
  }

  void checkValue(String source) {
    if (_pred.isKnown()) {
      debugPrint("${name()} = ${_pred.value()} based on $source");
    }
  }

  @override
  void finish() => _pred.finish();

  @override
  bool isKnown() => _pred.isKnown();

  @override
  bool value() => _pred.value();

  @override
  String toString() => _pred.toString();
}
