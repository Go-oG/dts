import 'package:dts/src/jts/algorithm/line_intersector.dart';
import 'package:dts/src/jts/algorithm/robust_line_intersector.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/topology_exception.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'mcindex_noder.dart';
import 'noding_intersection_finder.dart';

class FastNodingValidator {
  static List<Coordinate> computeIntersections(List<SegmentString> segStrings) {
    FastNodingValidator nv = FastNodingValidator(segStrings);
    nv.setFindAllIntersections(true);
    nv.isValid();
    return nv.getIntersections();
  }

  LineIntersector li = RobustLineIntersector();

  final List<SegmentString> _segStrings;

  bool _findAllIntersections = false;

  NodingIntersectionFinder? _segInt;

  bool _isValid = true;

  FastNodingValidator(this._segStrings);

  void setFindAllIntersections(bool findAllIntersections) {
    _findAllIntersections = findAllIntersections;
  }

  List<Coordinate> getIntersections() {
    return _segInt!.getIntersections();
  }

  bool isValid() {
    execute();
    return _isValid;
  }

  String getErrorMessage() {
    if (_isValid) return "no intersections found";

    final intSegs = _segInt!.getIntersectionSegments();
    return (("found non-noded intersection between $intSegs"));
  }

  void checkValid() {
    execute();
    if (!_isValid) {
      throw TopologyException(getErrorMessage(), _segInt!.getIntersection());
    }
  }

  void execute() {
    if (_segInt != null) {
      return;
    }

    checkInteriorIntersections();
  }

  void checkInteriorIntersections() {
    _isValid = true;
    _segInt = NodingIntersectionFinder(li);
    _segInt!.setFindAllIntersections(_findAllIntersections);
    final noder = MCIndexNoder();
    noder.setSegmentIntersector(_segInt!);
    noder.computeNodes(_segStrings);
    if (_segInt!.hasIntersection()) {
      _isValid = false;
      return;
    }
  }
}
