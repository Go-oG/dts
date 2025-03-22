 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'intersection_adder.dart';
import 'mcindex_noder.dart';
import 'noder.dart';

class IteratedNoder implements Noder {
  static const int MAX_ITER = 5;

  PrecisionModel pm;

  late LineIntersector li;

  List<SegmentString>? nodedSegStrings;

  int _maxIter = MAX_ITER;

  IteratedNoder(this.pm) {
    li = RobustLineIntersector();
    li.setPrecisionModel(pm);
  }

  void setMaximumIterations(int maxIter) {
    _maxIter = maxIter;
  }

  @override
  List<SegmentString>? getNodedSubstrings() {
    return nodedSegStrings;
  }

  @override
  void computeNodes(List<SegmentString> segStrings) {
    Array<int> numInteriorIntersections = Array(1);
    nodedSegStrings = segStrings;

    int nodingIterationCount = 0;
    int lastNodesCreated = -1;

    do {
      node(nodedSegStrings!, numInteriorIntersections);
      nodingIterationCount++;
      int nodesCreated = numInteriorIntersections[0];
      if (((lastNodesCreated > 0) && (nodesCreated >= lastNodesCreated)) && (nodingIterationCount > _maxIter)) {
        throw TopologyException(("Iterated noding failed to converge after $nodingIterationCount iterations"));
      }
      lastNodesCreated = nodesCreated;
    } while (lastNodesCreated > 0);
  }

  void node(List<SegmentString> segStrings, Array<int> numInteriorIntersections) {
    final si = IntersectionAdder(li);
    final noder = MCIndexNoder();
    noder.setSegmentIntersector(si);
    noder.computeNodes(segStrings);
    nodedSegStrings = noder.getNodedSubstrings();
    numInteriorIntersections[0] = si.numInteriorIntersections;
  }
}
