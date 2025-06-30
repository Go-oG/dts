import 'package:dts/src/jts/geom/geom.dart';
import 'package:dts/src/jts/geom/geom_component_filter.dart';
import 'package:dts/src/jts/geom/geom_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/polygon.dart';

import 'edge_ring.dart';
import 'hole_assigner.dart';
import 'polygonize_directed_edge.dart';
import 'polygonize_graph.dart';

class Polygonizer {
  late final _lineStringAdder = LineStringAdder(this);

  PolygonizeGraph? graph;

  List<LineString> dangles = [];

  List<LineString> cutEdges = [];

  List<LineString> invalidRingLines = [];

  //late init
  List<EdgeRingO>? holeList;

  //late init
  List<EdgeRingO>? shellList;

  //late init
  List<Polygon>? polyList;

  bool _isCheckingRingsValid = true;

  final bool _extractOnlyPolygonal;

  GeomFactory? _geomFactory;

  Polygonizer([this._extractOnlyPolygonal = false]);

  void add(List<Geometry> geomList) {
    for (var ge in geomList) {
      add2(ge);
    }
  }

  void add2(Geometry g) {
    g.apply4(_lineStringAdder);
  }

  void add3(LineString line) {
    _geomFactory = line.factory;
    graph ??= PolygonizeGraph(_geomFactory!);
    graph!.addEdge(line);
  }

  void setCheckRingsValid(bool isCheckingRingsValid) {
    _isCheckingRingsValid = isCheckingRingsValid;
  }

  List<Polygon> getPolygons() {
    polygonize();
    return polyList!;
  }

  Geometry getGeometry() {
    _geomFactory ??= GeomFactory();

    polygonize();
    if (_extractOnlyPolygonal) {
      return _geomFactory!.buildGeometry(polyList!);
    }
    return _geomFactory!.createGeomCollection(GeomFactory.toGeometryArray(polyList!)!);
  }

  List<LineString> getDangles() {
    polygonize();
    return dangles;
  }

  List<LineString> getCutEdges() {
    polygonize();
    return cutEdges;
  }

  List<LineString> getInvalidRingLines() {
    polygonize();
    return invalidRingLines;
  }

  void polygonize() {
    if (polyList != null) {
      return;
    }

    polyList = [];
    final graph = this.graph;
    if (graph == null) {
      return;
    }

    dangles = graph.deleteDangles();
    cutEdges = graph.deleteCutEdges();
    List<EdgeRingO> edgeRingList = graph.getEdgeRings();
    List<EdgeRingO> validEdgeRingList = [];
    List<EdgeRingO> invalidRings = [];
    if (_isCheckingRingsValid) {
      findValidRings(edgeRingList, validEdgeRingList, invalidRings);
      invalidRingLines = extractInvalidLines(invalidRings);
    } else {
      validEdgeRingList = edgeRingList;
    }
    findShellsAndHoles(validEdgeRingList);
    HoleAssigner.assignHolesToShells2(holeList!, shellList!);

    shellList!.sort(EdgeRingEnvelopeComparator().compare);

    bool includeAll = true;
    if (_extractOnlyPolygonal) {
      findDisjointShells(shellList!);
      includeAll = false;
    }
    polyList = extractPolygons(shellList!, includeAll);
  }

  void findValidRings(
    List<EdgeRingO> edgeRingList,
    List<EdgeRingO> validEdgeRingList,
    List<EdgeRingO> invalidRingList,
  ) {
    for (EdgeRingO er in edgeRingList) {
      er.computeValid();
      if (er.isValid()) {
        validEdgeRingList.add(er);
      } else {
        invalidRingList.add(er);
      }
    }
  }

  void findShellsAndHoles(List<EdgeRingO> edgeRingList) {
    holeList = [];
    shellList = [];
    for (EdgeRingO er in edgeRingList) {
      er.computeHole();
      if (er.isHole) {
        holeList!.add(er);
      } else {
        shellList!.add(er);
      }
    }
  }

  static void findDisjointShells(List<EdgeRingO> shellList) {
    findOuterShells(shellList);
    bool isMoreToScan;
    do {
      isMoreToScan = false;
      for (EdgeRingO er in shellList) {
        if (er.isIncludedSet()) {
          continue;
        }

        er.updateIncluded();
        if (!er.isIncludedSet()) {
          isMoreToScan = true;
        }
      }
    } while (isMoreToScan);
  }

  static void findOuterShells(List<EdgeRingO> shellList) {
    for (EdgeRingO er in shellList) {
      EdgeRingO? outerHoleER = er.getOuterHole();
      if ((outerHoleER != null) && (!outerHoleER.isProcessed())) {
        er.setIncluded(true);
        outerHoleER.setProcessed(true);
      }
    }
  }

  List<LineString> extractInvalidLines(List<EdgeRingO> invalidRings) {
    invalidRings.sort(EdgeRingEnvelopeAreaComparator().compare);
    List<LineString> invalidLines = [];
    for (EdgeRingO er in invalidRings) {
      if (isIncludedInvalid(er)) {
        invalidLines.add(er.getLineString());
      }
      er.setProcessed(true);
    }
    return invalidLines;
  }

  bool isIncludedInvalid(EdgeRingO invalidRing) {
    for (var de in invalidRing.getEdges()) {
      PolygonizeDirectedEdge deAdj = de.getSym() as PolygonizeDirectedEdge;
      EdgeRingO erAdj = deAdj.getRing()!;
      bool isEdgeIncluded = erAdj.isValid() || erAdj.isProcessed();
      if (!isEdgeIncluded) {
        return true;
      }
    }
    return false;
  }

  static List<Polygon> extractPolygons(List<EdgeRingO> shellList, bool includeAll) {
    List<Polygon> polyList = [];
    for (EdgeRingO er in shellList) {
      if (includeAll || er.isIncluded()) {
        polyList.add(er.getPolygon());
      }
    }
    return polyList;
  }
}

class LineStringAdder implements GeomComponentFilter {
  Polygonizer p;

  LineStringAdder(this.p);

  @override
  void filter(Geometry g) {
    if (g is LineString) {
      p.add3(g);
    }
  }
}
