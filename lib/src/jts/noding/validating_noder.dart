import 'fast_noding_validator.dart';
import 'noder.dart';
import 'segment_string.dart';

class ValidatingNoder implements Noder {
  final Noder _noder;

  List<SegmentString>? _nodedSS;

  ValidatingNoder(this._noder);

  @override
  void computeNodes(List<SegmentString> segStrings) {
    _noder.computeNodes(segStrings);
    _nodedSS = _noder.getNodedSubstrings();
    validate();
  }

  void validate() {
    final nv = FastNodingValidator(_nodedSS!);
    nv.checkValid();
  }

  @override
  List<SegmentString>? getNodedSubstrings() {
    return _nodedSS;
  }
}
