import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/dimension.dart';

import 'node_section.dart';

class PolygonNodeConverter {
  static List<NodeSection> convert(List<NodeSection> polySections) {
    polySections.sort(NodeSectionEdgeAngleComparator().compare);
    List<NodeSection> sections = extractUnique(polySections);
    if (sections.length == 1) return sections;

    int shellIndex = findShell(sections);
    if (shellIndex < 0) {
      return convertHoles(sections);
    }
    List<NodeSection> convertedSections = [];
    int nextShellIndex = shellIndex;
    do {
      nextShellIndex =
          convertShellAndHoles(sections, nextShellIndex, convertedSections);
    } while (nextShellIndex != shellIndex);
    return convertedSections;
  }

  static int convertShellAndHoles(List<NodeSection> sections, int shellIndex,
      List<NodeSection> convertedSections) {
    NodeSection shellSection = sections.get(shellIndex);
    Coordinate? inVertex = shellSection.getVertex(0);
    int i = next(sections, shellIndex);
    NodeSection? holeSection;
    while (!sections.get(i).isShell()) {
      holeSection = sections.get(i);
      final outVertex = holeSection.getVertex(1);
      NodeSection ns = createSection(shellSection, inVertex, outVertex);
      convertedSections.add(ns);
      inVertex = holeSection.getVertex(0);
      i = next(sections, i);
    }
    final outVertex = shellSection.getVertex(1);
    NodeSection ns = createSection(shellSection, inVertex, outVertex);
    convertedSections.add(ns);
    return i;
  }

  static List<NodeSection> convertHoles(List<NodeSection> sections) {
    List<NodeSection> convertedSections = [];
    NodeSection copySection = sections.get(0);
    for (int i = 0; i < sections.size; i++) {
      int inext = next(sections, i);
      Coordinate? inVertex = sections.get(i).getVertex(0);
      Coordinate? outVertex = sections.get(inext).getVertex(1);
      NodeSection ns = createSection(copySection, inVertex, outVertex);
      convertedSections.add(ns);
    }
    return convertedSections;
  }

  static NodeSection createSection(
      NodeSection ns, Coordinate? v0, Coordinate? v1) {
    return NodeSection(ns.isA(), Dimension.A, ns.id, 0, ns.getPolygonal(),
        ns.isNodeAtVertex(), v0, ns.nodePt(), v1);
  }

  static List<NodeSection> extractUnique(List<NodeSection> sections) {
    List<NodeSection> uniqueSections = [];
    NodeSection lastUnique = sections.get(0);
    uniqueSections.add(lastUnique);
    for (NodeSection ns in sections) {
      if (0 != lastUnique.compareTo(ns)) {
        uniqueSections.add(ns);
        lastUnique = ns;
      }
    }
    return uniqueSections;
  }

  static int next(List<NodeSection> ns, int i) {
    int next = i + 1;
    if (next >= ns.size) {
      next = 0;
    }

    return next;
  }

  static int findShell(List<NodeSection> polySections) {
    for (int i = 0; i < polySections.size; i++) {
      if (polySections.get(i).isShell()) {
        return i;
      }
    }
    return -1;
  }
}
