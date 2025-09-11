import 'package:dts/src/jts/geom/envelope.dart';
import 'package:dts/src/jts/index/spatial_index.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';

import 'edge_ring.dart';

class HoleAssigner {
  static void assignHolesToShells2(
      List<EdgeRingO> holes, List<EdgeRingO> shells) {
    HoleAssigner assigner = HoleAssigner(shells);
    assigner.assignHolesToShells(holes);
  }

  final List<EdgeRingO> _shells;

  late final SpatialIndex<EdgeRingO> _shellIndex;

  HoleAssigner(this._shells) {
    buildIndex();
  }

  void buildIndex() {
    _shellIndex = STRtree();
    for (EdgeRingO shell in _shells) {
      _shellIndex.insert(shell.getRing().getEnvelopeInternal(), shell);
    }
  }

  void assignHolesToShells(List<EdgeRingO> holeList) {
    for (EdgeRingO holeER in holeList) {
      assignHoleToShell(holeER);
    }
  }

  void assignHoleToShell(EdgeRingO holeER) {
    EdgeRingO? shell = findShellContaining(holeER);
    if (shell != null) {
      shell.addHole(holeER);
    }
  }

  List<EdgeRingO> queryOverlappingShells(Envelope ringEnv) {
    return _shellIndex.query(ringEnv);
  }

  EdgeRingO? findShellContaining(EdgeRingO testEr) {
    Envelope testEnv = testEr.getRing().getEnvelopeInternal();
    List<EdgeRingO> candidateShells = queryOverlappingShells(testEnv);
    return EdgeRingO.findEdgeRingContaining(testEr, candidateShells);
  }
}
