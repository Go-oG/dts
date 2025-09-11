import '../geom/geometry.dart';
import '../geom/geometry_factory.dart';
import '../geom/line_string.dart';
import '../geom/util/linear_component_extracter.dart';
import 'basic_segment_string.dart';
import 'noded_segment_string.dart';
import 'segment_string.dart';

class SegmentStringUtil {
  static List<NodedSegmentString> extractSegmentStrings(Geometry geom) {
    return extractNodedSegmentStrings(geom);
  }

  static List<NodedSegmentString> extractNodedSegmentStrings(Geometry geom) {
    List<NodedSegmentString> segStr = [];
    List<LineString> lines = LinearComponentExtracter.getLines(geom);
    for (var line in lines) {
      segStr.add(NodedSegmentString(line.getCoordinates(), geom));
    }

    return segStr;
  }

  static List<BasicSegmentString> extractBasicSegmentStrings(Geometry geom) {
    List<BasicSegmentString> segStr = [];
    for (var line in LinearComponentExtracter.getLines(geom)) {
      segStr.add(BasicSegmentString(line.getCoordinates(), geom));
    }
    return segStr;
  }

  static Geometry toGeometry(
      List<SegmentString> segStrings, GeometryFactory geomFact) {
    List<LineString> lines = [];
    for (var ss in segStrings) {
      lines.add(geomFact.createLineString2(ss.getCoordinates()));
    }
    if (lines.length == 1) {
      return lines[0];
    }

    return geomFact.createMultiLineString(lines);
  }

  static String toStringS(List<SegmentString> segStrings) {
    StringBuffer buf = StringBuffer();
    for (var segStr in segStrings) {
      buf.write(segStr.toString());
      buf.write("\n");
    }
    return buf.toString();
  }
}
