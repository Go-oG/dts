import 'package:dts/src/jts/geom/coordinate_sequence.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_component_filter.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/point.dart';
import 'package:dts/src/jts/index/strtree/strtree.dart';

import 'facet_sequence.dart';

class FacetSequenceTreeBuilder {
  static const int _kFacetSequenceSize = 6;

  static const int _kSTRTreeNodeCapacity = 4;

  static STRtree<FacetSequence> build(Geometry g) {
    STRtree<FacetSequence> tree = STRtree(_kSTRTreeNodeCapacity);
    final sections = computeFacetSequences(g);
    for (var section in sections) {
      tree.insert(section.getEnvelope(), section);
    }
    tree.build();
    return tree;
  }

  static List<FacetSequence> computeFacetSequences(Geometry g) {
    final List<FacetSequence> sections = [];
    g.apply4(
      GeomComponentFilter2((geom) {
        CoordinateSequence? seq;
        if (geom is LineString) {
          seq = geom.getCoordinateSequence();
          addFacetSequences(geom, seq, sections);
        } else if (geom is Point) {
          seq = geom.getCoordinateSequence();
          addFacetSequences(geom, seq, sections);
        }
      }),
    );
    return sections;
  }

  static void addFacetSequences(Geometry geom, CoordinateSequence pts, List<FacetSequence> sections) {
    int i = 0;
    int size = pts.size();
    while (i <= (size - 1)) {
      int end = (i + _kFacetSequenceSize) + 1;
      if (end >= (size - 1)) {
        end = size;
      }

      FacetSequence sect = FacetSequence(geom, pts, i, end);
      sections.add(sect);
      i = i + _kFacetSequenceSize;
    }
  }
}
