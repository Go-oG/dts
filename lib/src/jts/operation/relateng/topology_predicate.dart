import 'package:dts/src/jts/geom/envelope.dart';

abstract class TopologyPredicate {
  String name();

  bool requireSelfNoding() {
    return true;
  }

  bool requireInteraction() {
    return true;
  }

  bool requireCovers(bool isSourceA) {
    return false;
  }

  bool requireExteriorCheck(bool isSourceA) {
    return true;
  }

  void init(int dimA, int dimB) {}

  void init2(Envelope envA, Envelope envB) {}

  void updateDimension(int locA, int locB, int dimension);

  void finish();

  bool isKnown();

  bool value();
}
