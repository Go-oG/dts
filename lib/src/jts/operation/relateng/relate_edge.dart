 import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/polygon_node_topology.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/dimension.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/util/assert.dart';

import 'relate_node.dart';

class RelateEdge {
  static RelateEdge create(RelateNGNode node, Coordinate dirPt, bool isA, int dim, bool isForward) {
    if (dim == Dimension.A) {
      return RelateEdge(node, dirPt, isA, isForward);
    }

    return RelateEdge.of(node, dirPt, isA);
  }

  static int findKnownEdgeIndex(List<RelateEdge> edges, bool isA) {
    for (int i = 0; i < edges.size; i++) {
      RelateEdge e = edges.get(i);
      if (e.isKnown(isA)) {
        return i;
      }
    }
    return -1;
  }

  static void setAreaInterior2(List<RelateEdge> edges, bool isA) {
    for (RelateEdge e in edges) {
      e.setAreaInterior(isA);
    }
  }

  static const int _dimUnknown = -1;
  static const int _locUnknown = Location.none;

  final RelateNGNode _node;

  Coordinate dirPt;

  int _aDim = _dimUnknown;

  int _aLocLeft = _locUnknown;

  int _aLocRight = _locUnknown;

  int _aLocLine = _locUnknown;

  int _bDim = _dimUnknown;

  int _bLocLeft = _locUnknown;

  int _bLocRight = _locUnknown;

  int _bLocLine = _locUnknown;

  RelateEdge(this._node, this.dirPt, bool isA, bool isForward) {
    setLocationsArea(isA, isForward);
  }

  RelateEdge.of(this._node, this.dirPt, bool isA) {
    setLocationsLine(isA);
  }

  RelateEdge.of2(this._node, this.dirPt, bool isA, int locLeft, int locRight, int locLine) {
    setLocations(isA, locLeft, locRight, locLine);
  }

  void setLocations(bool isA, int locLeft, int locRight, int locLine) {
    if (isA) {
      _aDim = 2;
      _aLocLeft = locLeft;
      _aLocRight = locRight;
      _aLocLine = locLine;
    } else {
      _bDim = 2;
      _bLocLeft = locLeft;
      _bLocRight = locRight;
      _bLocLine = locLine;
    }
  }

  void setLocationsLine(bool isA) {
    if (isA) {
      _aDim = 1;
      _aLocLeft = Location.exterior;
      _aLocRight = Location.exterior;
      _aLocLine = Location.interior;
    } else {
      _bDim = 1;
      _bLocLeft = Location.exterior;
      _bLocRight = Location.exterior;
      _bLocLine = Location.interior;
    }
  }

  void setLocationsArea(bool isA, bool isForward) {
    int locLeft = (isForward) ? Location.exterior : Location.interior;
    int locRight = (isForward) ? Location.interior : Location.exterior;
    if (isA) {
      _aDim = 2;
      _aLocLeft = locLeft;
      _aLocRight = locRight;
      _aLocLine = Location.boundary;
    } else {
      _bDim = 2;
      _bLocLeft = locLeft;
      _bLocRight = locRight;
      _bLocLine = Location.boundary;
    }
  }

  int compareToEdge(Coordinate edgeDirPt) {
    return PolygonNodeTopology.compareAngle(_node.getCoordinate(), dirPt, edgeDirPt);
  }

  void merge(bool isA, Coordinate dirPt, int dim, bool isForward) {
    int locEdge = Location.interior;
    int locLeft = Location.exterior;
    int locRight = Location.exterior;
    if (dim == Dimension.A) {
      locEdge = Location.boundary;
      locLeft = (isForward) ? Location.exterior : Location.interior;
      locRight = (isForward) ? Location.interior : Location.exterior;
    }
    if (!isKnown(isA)) {
      setDimension(isA, dim);
      setOn(isA, locEdge);
      setLeft(isA, locLeft);
      setRight(isA, locRight);
      return;
    }
    mergeDimEdgeLoc(isA, locEdge);
    mergeSideLocation(isA, Position.left, locLeft);
    mergeSideLocation(isA, Position.right, locRight);
  }

  void mergeDimEdgeLoc(bool isA, int locEdge) {
    int dim = (locEdge == Location.boundary) ? Dimension.A : Dimension.L;
    if ((dim == Dimension.A) && (dimension(isA) == Dimension.L)) {
      setDimension(isA, dim);
      setOn(isA, Location.boundary);
    }
  }

  void mergeSideLocation(bool isA, int pos, int loc) {
    int currLoc = location(isA, pos);
    if (currLoc != Location.interior) {
      setLocation(isA, pos, loc);
    }
  }

  void setDimension(bool isA, int dimension) {
    if (isA) {
      _aDim = dimension;
    } else {
      _bDim = dimension;
    }
  }

  void setLocation(bool isA, int pos, int loc) {
    switch (pos) {
      case Position.left:
        setLeft(isA, loc);
        break;
      case Position.right:
        setRight(isA, loc);
        break;
      case Position.on:
        setOn(isA, loc);
        break;
    }
  }

  void setAllLocations(bool isA, int loc) {
    setLeft(isA, loc);
    setRight(isA, loc);
    setOn(isA, loc);
  }

  void setUnknownLocations(bool isA, int loc) {
    if (!isKnown2(isA, Position.left)) {
      setLocation(isA, Position.left, loc);
    }
    if (!isKnown2(isA, Position.right)) {
      setLocation(isA, Position.right, loc);
    }
    if (!isKnown2(isA, Position.on)) {
      setLocation(isA, Position.on, loc);
    }
  }

  void setLeft(bool isA, int loc) {
    if (isA) {
      _aLocLeft = loc;
    } else {
      _bLocLeft = loc;
    }
  }

  void setRight(bool isA, int loc) {
    if (isA) {
      _aLocRight = loc;
    } else {
      _bLocRight = loc;
    }
  }

  void setOn(bool isA, int loc) {
    if (isA) {
      _aLocLine = loc;
    } else {
      _bLocLine = loc;
    }
  }

  int location(bool isA, int position) {
    if (isA) {
      switch (position) {
        case Position.left:
          return _aLocLeft;
        case Position.right:
          return _aLocRight;
        case Position.on:
          return _aLocLine;
      }
    } else {
      switch (position) {
        case Position.left:
          return _bLocLeft;
        case Position.right:
          return _bLocRight;
        case Position.on:
          return _bLocLine;
      }
    }
    Assert.shouldNeverReachHere();
    return _locUnknown;
  }

  int dimension(bool isA) {
    return isA ? _aDim : _bDim;
  }

  bool isKnown(bool isA) {
    if (isA) {
      return _aDim != _dimUnknown;
    }

    return _bDim != _dimUnknown;
  }

  bool isKnown2(bool isA, int pos) {
    return location(isA, pos) != _locUnknown;
  }

  bool isInterior(bool isA, int position) {
    return location(isA, position) == Location.interior;
  }

  void setDimLocations(bool isA, int dim, int loc) {
    if (isA) {
      _aDim = dim;
      _aLocLeft = loc;
      _aLocRight = loc;
      _aLocLine = loc;
    } else {
      _bDim = dim;
      _bLocLeft = loc;
      _bLocRight = loc;
      _bLocLine = loc;
    }
  }

  void setAreaInterior(bool isA) {
    if (isA) {
      _aLocLeft = Location.interior;
      _aLocRight = Location.interior;
      _aLocLine = Location.interior;
    } else {
      _bLocLeft = Location.interior;
      _bLocRight = Location.interior;
      _bLocLine = Location.interior;
    }
  }
}
