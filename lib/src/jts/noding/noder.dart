import 'segment_string.dart';

abstract interface class Noder {
  void computeNodes(List<SegmentString> segStrings);

  List<SegmentString>? getNodedSubstrings();
}
