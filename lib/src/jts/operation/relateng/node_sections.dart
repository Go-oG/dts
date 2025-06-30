import '../../geom/coordinate.dart';
import '../../geom/geom.dart';
import 'node_section.dart';
import 'polygon_node_converter.dart';
import 'relate_node.dart';

class NodeSections {
  final Coordinate nodePt;

  final List<NodeSection> _sections = [];

  NodeSections(this.nodePt);

  Coordinate getCoordinate() {
    return nodePt;
  }

  void addNodeSection(NodeSection e) {
    _sections.add(e);
  }

  bool hasInteractionAB() {
    bool isA = false;
    bool isB = false;
    for (NodeSection ns in _sections) {
      if (ns.isA()) {
        isA = true;
      } else {
        isB = true;
      }

      if (isA && isB) {
        return true;
      }
    }
    return false;
  }

  Geometry? getPolygonal(bool isA) {
    for (NodeSection ns in _sections) {
      if (ns.isA() == isA) {
        Geometry? poly = ns.getPolygonal();
        if (poly != null) return poly;
      }
    }
    return null;
  }

  RelateNGNode createNode() {
    prepareSections();
    final node = RelateNGNode(nodePt);
    int i = 0;
    while (i < _sections.length) {
      NodeSection ns = _sections[i];
      if (ns.isArea() && hasMultiplePolygonSections(_sections, i)) {
        List<NodeSection> polySections = collectPolygonSections(_sections, i);
        List<NodeSection> nsConvert = PolygonNodeConverter.convert(polySections);
        node.addEdges2(nsConvert);
        i += polySections.length;
      } else {
        node.addEdges(ns);
        i += 1;
      }
    }
    return node;
  }

  void prepareSections() {
    _sections.sort(null);
  }

  static bool hasMultiplePolygonSections(List<NodeSection> sections, int i) {
    if (i >= (sections.length - 1)) return false;

    NodeSection ns = sections[i];
    NodeSection nsNext = sections[i + 1];
    return ns.isSamePolygon(nsNext);
  }

  static List<NodeSection> collectPolygonSections(List<NodeSection> sections, int i) {
    List<NodeSection> polySections = [];
    NodeSection polySection = sections[i];
    while ((i < sections.length) && polySection.isSamePolygon(sections[i])) {
      polySections.add(sections[i]);
      i++;
    }
    return polySections;
  }
}
