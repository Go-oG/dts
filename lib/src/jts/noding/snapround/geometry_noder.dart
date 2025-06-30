import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/util/linear_component_extracter.dart';
import 'package:dts/src/jts/noding/noded_segment_string.dart';
import 'package:dts/src/jts/noding/noder.dart';
import 'package:dts/src/jts/noding/noding_validator.dart';
import 'package:dts/src/jts/noding/segment_string.dart';

import 'snap_rounding_noder.dart';

class GeometryNoder {
  late GeomFactory geomFact;

  final PrecisionModel _pm;

  bool _isValidityChecked = false;

  GeometryNoder(this._pm);

  void setValidate(bool isValidityChecked) {
    _isValidityChecked = isValidityChecked;
  }

  List<LineString> node(List<Geometry> geoms) {
    Geometry geom0 = geoms.first;
    geomFact = geom0.factory;
    final segStrings = toSegmentStrings(extractLines(geoms));
    Noder sr = SnapRoundingNoder(_pm);
    sr.computeNodes(segStrings);
    final nodedLines = sr.getNodedSubstrings()!;
    if (_isValidityChecked) {
      NodingValidator nv = NodingValidator(nodedLines);
      nv.checkValid();
    }
    return toLineStrings(nodedLines);
  }

  List<LineString> toLineStrings(List<SegmentString> segStrings) {
    List<LineString> lines = [];
    for (var ss in segStrings) {
      if (ss.size() < 2) {
        continue;
      }
      lines.add(geomFact.createLineString2(ss.getCoordinates()));
    }
    return lines;
  }

  List<LineString> extractLines(List<Geometry> geoms) {
    List<LineString> lines = [];
    final lce = LinearComponentExtracter(lines);
    for (var geom in geoms) {
      geom.apply4(lce);
    }
    return lines;
  }

  List<NodedSegmentString> toSegmentStrings(List<LineString> lines) {
    List<NodedSegmentString> segStrings = [];
    for (var line in lines) {
      segStrings.add(NodedSegmentString(line.getCoordinates(), null));
    }
    return segStrings;
  }
}
