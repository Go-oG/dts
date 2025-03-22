import 'package:dts/src/jts/geom/coordinate.dart';

import 'constraint_vertex.dart';
import 'segment.dart';

abstract interface class ConstraintVertexFactory {
  ConstraintVertex createVertex(Coordinate p, Segment? constraintSeg);
}
