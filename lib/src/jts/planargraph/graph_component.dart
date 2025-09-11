abstract class GraphComponentPG {
  static void setVisited2(Iterable<GraphComponentPG> i, bool visited) {
    for (var comp in i) {
      comp.isVisited = visited;
    }
  }

  static void setMarked2(Iterable<GraphComponentPG> i, bool marked) {
    for (var item in i) {
      item.isMarked = marked;
    }
  }

  static GraphComponentPG? getComponentWithVisitedState(
      Iterator<GraphComponentPG> i, bool visitedState) {
    while (i.moveNext()) {
      GraphComponentPG comp = i.current;
      if (comp.isVisited == visitedState) return comp;
    }
    return null;
  }

  bool isMarked = false;

  bool isVisited = false;

  Object? data;

  void setContext(Object? data) {
    this.data = data;
  }

  Object? getContext() {
    return data;
  }

  bool isRemoved();
}
