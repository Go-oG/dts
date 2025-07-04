import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/util/geom_editor.dart';

import 'pointwise_precision_reducer_transformer.dart';
import 'precision_reducer_transformer.dart';

class GeometryPrecisionReducer {
  static Geometry? reduce2(Geometry g, PrecisionModel pm) {
    final reducer = GeometryPrecisionReducer(pm);
    return reducer.reduce(g);
  }

  static Geometry? reduceKeepCollapsed(Geometry geom, PrecisionModel pm) {
    final reducer = GeometryPrecisionReducer(pm);
    reducer.setRemoveCollapsedComponents(false);
    return reducer.reduce(geom);
  }

  static Geometry? reducePointwise(Geometry g, PrecisionModel pm) {
    final reducer = GeometryPrecisionReducer(pm);
    reducer.setPointwise(true);
    return reducer.reduce(g);
  }

  final PrecisionModel _targetPM;

  bool _removeCollapsed = true;

  bool _changePrecisionModel = false;

  bool _isPointwise = false;

  GeometryPrecisionReducer(this._targetPM);

  void setRemoveCollapsedComponents(bool removeCollapsed) {
    _removeCollapsed = removeCollapsed;
  }

  void setChangePrecisionModel(bool changePrecisionModel) {
    _changePrecisionModel = changePrecisionModel;
  }

  void setPointwise(bool isPointwise) {
    _isPointwise = isPointwise;
  }

  Geometry? reduce(Geometry geom) {
    Geometry reduced;
    if (_isPointwise) {
      reduced = PointwisePrecisionReducerTransformer.reduce(geom, _targetPM)!;
    } else {
      reduced = PrecisionReducerTransformer.reduce(geom, _targetPM, _removeCollapsed)!;
    }
    if (_changePrecisionModel) {
      return changePM(reduced, _targetPM);
    }
    return reduced;
  }

  Geometry? changePM(Geometry geom, PrecisionModel newPM) {
    GeometryEditor geomEditor = createEditor(geom.factory, newPM);
    return geomEditor.edit(geom, NoOpGeometryOperation());
  }

  GeometryEditor createEditor(GeometryFactory geomFactory, PrecisionModel newPM) {
    if (geomFactory.getPrecisionModel() == newPM) {
      return GeometryEditor.empty();
    }

    GeometryFactory newFactory = createFactory(geomFactory, newPM);
    GeometryEditor geomEdit = GeometryEditor(newFactory);
    return geomEdit;
  }

  GeometryFactory createFactory(GeometryFactory inputFactory, PrecisionModel pm) {
    GeometryFactory newFactory =
        GeometryFactory(pm: pm, srid: inputFactory.srid, csFactory: inputFactory.csFactory);
    return newFactory;
  }
}
