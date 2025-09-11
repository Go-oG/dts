import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/coordinate_list.dart';
import 'package:dts/src/jts/geom/geometry.dart';
import 'package:dts/src/jts/geom/geometry_factory.dart';
import 'package:dts/src/jts/geom/line_string.dart';
import 'package:dts/src/jts/geom/linear_ring.dart';
import 'package:dts/src/jts/geom/precision_model.dart';
import 'package:dts/src/jts/geom/util/geom_editor.dart';

class SimpleGeometryPrecisionReducer {
  static Geometry? reduce2(Geometry g, PrecisionModel pm) {
    SimpleGeometryPrecisionReducer reducer = SimpleGeometryPrecisionReducer(pm);
    return reducer.reduce(g);
  }

  final PrecisionModel _newPrecisionModel;

  bool removeCollapsed = true;

  bool changePrecisionModel = false;

  SimpleGeometryPrecisionReducer(this._newPrecisionModel);

  void setRemoveCollapsedComponents(bool removeCollapsed) {
    this.removeCollapsed = removeCollapsed;
  }

  void setChangePrecisionModel(bool changePrecisionModel) {
    this.changePrecisionModel = changePrecisionModel;
  }

  Geometry? reduce(Geometry geom) {
    GeometryEditor geomEdit;
    if (changePrecisionModel) {
      GeometryFactory newFactory =
          GeometryFactory(pm: _newPrecisionModel, srid: geom.factory.srid);
      geomEdit = GeometryEditor(newFactory);
    } else {
      geomEdit = GeometryEditor.empty();
    }

    return geomEdit.edit(geom, _PrecisionReducerCoordinateOperation(this));
  }
}

class _PrecisionReducerCoordinateOperation extends CoordinateOperation {
  final SimpleGeometryPrecisionReducer _parent;

  _PrecisionReducerCoordinateOperation(this._parent);

  @override
  List<Coordinate>? edit2(List<Coordinate> coordinates, Geometry geom) {
    if (coordinates.isEmpty) return null;

    List<Coordinate> reducedCoords = [];
    for (int i = 0; i < coordinates.length; i++) {
      Coordinate coord = Coordinate.of(coordinates[i]);
      _parent._newPrecisionModel.makePrecise(coord);
      reducedCoords.add(coord);
    }
    final noRepeatedCoordList = CoordinateList(reducedCoords, false);
    final noRepeatedCoords = noRepeatedCoordList.toCoordinateList();
    int minLength = 0;
    if (geom is LineString) minLength = 2;

    if (geom is LinearRing) minLength = 4;

    List<Coordinate>? collapsedCoords = reducedCoords;
    if (_parent.removeCollapsed) {
      collapsedCoords = null;
    }

    if (noRepeatedCoords.length < minLength) {
      return collapsedCoords;
    }
    return noRepeatedCoords;
  }
}
