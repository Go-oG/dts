import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/algorithm/orientation.dart';
import 'package:dts/src/jts/geom/coordinate.dart';
import 'package:dts/src/jts/geom/position.dart';
import 'package:dts/src/jts/geomgraph/edge.dart';
import 'package:dts/src/jts/geomgraph/node.dart';
import 'package:dts/src/jts/util/assert.dart';

class RightmostEdgeFinder {
  int _minIndex = -1;
  Coordinate? _minCoord;
  DirectedEdge? _minDe;
  DirectedEdge? _orientedDe;

  DirectedEdge? getEdge() {
    return _orientedDe;
  }

  Coordinate? getCoordinate() {
    return _minCoord;
  }

  void findEdge(List<DirectedEdge> dirEdgeList) {
    for (var de in dirEdgeList) {
      if (!de.isForward) continue;

      checkForRightmostCoordinate(de);
    }

    Assert.isTrue(
      (_minIndex != 0) || _minCoord! == (_minDe!.getCoordinate()),
      "inconsistency in rightmost processing",
    );
    if (_minIndex == 0) {
      findRightmostEdgeAtNode();
    } else {
      findRightmostEdgeAtVertex();
    }
    _orientedDe = _minDe;
    int rightmostSide = getRightmostSide(_minDe!, _minIndex);
    if (rightmostSide == Position.left) {
      _orientedDe = _minDe!.getSym();
    }
  }

  void findRightmostEdgeAtNode() {
    Node node = _minDe!.getNode();
    DirectedEdgeStar star = (node.getEdges() as DirectedEdgeStar);
    _minDe = star.getRightmostEdge();
    if (!_minDe!.isForward) {
      _minDe = _minDe!.getSym();
      _minIndex = _minDe!.getEdge().getCoordinates().length - 1;
    }
  }

  void findRightmostEdgeAtVertex() {
    Array<Coordinate> pts = _minDe!.getEdge().getCoordinates();
    Assert.isTrue(
      _minIndex > 0 && _minIndex < pts.length,
      "rightmost point expected to be interior vertex of edge",
    );
    Coordinate pPrev = pts[_minIndex - 1];
    Coordinate pNext = pts[_minIndex + 1];
    int orientation = Orientation.index(_minCoord!, pNext, pPrev);
    bool usePrev = false;
    if (((pPrev.y < _minCoord!.y) && (pNext.y < _minCoord!.y)) &&
        (orientation == Orientation.counterClockwise)) {
      usePrev = true;
    } else if (((pPrev.y > _minCoord!.y) && (pNext.y > _minCoord!.y)) &&
        (orientation == Orientation.clockwise)) {
      usePrev = true;
    }
    if (usePrev) {
      _minIndex = _minIndex - 1;
    }
  }

  void checkForRightmostCoordinate(DirectedEdge de) {
    Array<Coordinate> coord = de.getEdge().getCoordinates();
    for (int i = 0; i < (coord.length - 1); i++) {
      if ((_minCoord == null) || (coord[i].x > _minCoord!.x)) {
        _minDe = de;
        _minIndex = i;
        _minCoord = coord[i];
      }
    }
  }

  int getRightmostSide(DirectedEdge de, int index) {
    int side = getRightmostSideOfSegment(de, index);
    if (side < 0) side = getRightmostSideOfSegment(de, index - 1);

    if (side < 0) {
      _minCoord = null;
      checkForRightmostCoordinate(de);
    }
    return side;
  }

  int getRightmostSideOfSegment(DirectedEdge de, int i) {
    Edge e = de.getEdge();
    Array<Coordinate> coord = e.getCoordinates();
    if ((i < 0) || ((i + 1) >= coord.length)) {
      return -1;
    }

    if (coord[i].y == coord[i + 1].y) {
      return -1;
    }

    int pos = Position.left;
    if (coord[i].y < coord[i + 1].y) {
      pos = Position.right;
    }

    return pos;
  }
}
