import 'component_jump_checker.dart';
import 'line_segment_index.dart';
import 'tagged_line_string.dart';
import 'tagged_line_string_simplifier.dart';

class TaggedLinesSimplifier {
  final LineSegmentIndex _inputIndex = LineSegmentIndex();

  final LineSegmentIndex _outputIndex = LineSegmentIndex();

  double distanceTolerance = 0.0;

  void setDistanceTolerance(double distanceTolerance) {
    this.distanceTolerance = distanceTolerance;
  }

  void simplify(List<TaggedLineString> taggedLines) {
    final jumpChecker = ComponentJumpChecker(taggedLines);
    for (var i in taggedLines) {
      _inputIndex.add2(i);
    }
    for (var i in taggedLines) {
      final tlss = TaggedLineStringSimplifier(_inputIndex, _outputIndex, jumpChecker);
      tlss.simplify(i, distanceTolerance);
    }
  }
}
