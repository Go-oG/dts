import '../geom/coordinate.dart';
import 'noded_segment_string.dart';
import 'segment_point_comparator.dart';

class SegmentNode implements Comparable<SegmentNode> {
  final NodedSegmentString _segString;

  late final Coordinate coord;

  final int segmentIndex;

  final int _segmentOctant;

  late final bool _isInterior;

  SegmentNode(this._segString, Coordinate coord, this.segmentIndex,
      this._segmentOctant) {
    this.coord = coord.copy();
    _isInterior = !coord.equals2D(_segString.getCoordinate(segmentIndex));
  }

  Coordinate getCoordinate() {
    return coord;
  }

  bool isInterior() {
    return _isInterior;
  }

  bool isEndPoint(int maxSegmentIndex) {
    if ((segmentIndex == 0) && (!_isInterior)) return true;

    if (segmentIndex == maxSegmentIndex) return true;

    return false;
  }

  @override
  int compareTo(SegmentNode other) {
    if (segmentIndex < other.segmentIndex) return -1;

    if (segmentIndex > other.segmentIndex) return 1;

    if (coord.equals2D(other.coord)) return 0;

    if (!_isInterior) return -1;

    if (!other._isInterior) return 1;

    return SegmentPointComparator.compare(_segmentOctant, coord, other.coord);
  }
}
