import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/util/geom_combiner.dart';

class UnionInteracting {
  static Geometry? unionS(Geometry g0, Geometry g1) {
    UnionInteracting uue = UnionInteracting(g0, g1);
    return uue.union();
  }

  late final GeometryFactory geomFactory;

  Geometry g0;

  Geometry g1;

  late Array<bool> _interacts0;

  late Array<bool> _interacts1;

  UnionInteracting(this.g0, this.g1) {
    geomFactory = g0.factory;
    _interacts0 = Array(g0.getNumGeometries());
    _interacts1 = Array(g1.getNumGeometries());
  }

  Geometry? union() {
    _computeInteracting();
    Geometry int0 = extractElements(g0, _interacts0, true);
    Geometry int1 = extractElements(g1, _interacts1, true);
    Geometry union = int0.union2(int1)!;
    Geometry disjoint0 = extractElements(g0, _interacts0, false);
    Geometry disjoint1 = extractElements(g1, _interacts1, false);
    return GeometryCombiner.combine4(union, disjoint0, disjoint1);
  }

  void _computeInteracting() {
    for (int i = 0; i < g0.getNumGeometries(); i++) {
      Geometry elem = g0.getGeometryN(i);
      _interacts0[i] = _computeInteracting2(elem);
    }
  }

  bool _computeInteracting2(Geometry elem0) {
    bool interactsWithAny = false;
    for (int i = 0; i < g1.getNumGeometries(); i++) {
      Geometry elem1 = g1.getGeometryN(i);
      bool interacts = elem1.getEnvelopeInternal().intersects(elem0.getEnvelopeInternal());
      if (interacts) _interacts1[i] = true;

      if (interacts) interactsWithAny = true;
    }
    return interactsWithAny;
  }

  Geometry extractElements(Geometry geom, Array<bool> interacts, bool isInteracting) {
    List<Geometry> extractedGeoms = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      Geometry elem = geom.getGeometryN(i);
      if (interacts[i] == isInteracting) {
        extractedGeoms.add(elem);
      }
    }
    return geomFactory.buildGeometry(extractedGeoms);
  }
}
