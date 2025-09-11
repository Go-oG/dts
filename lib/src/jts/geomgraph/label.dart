import 'package:d_util/d_util.dart';
import 'package:dts/src/jts/geom/location.dart';
import 'package:dts/src/jts/geom/position.dart';

import 'topology_location.dart';

class Label {
  static Label toLineLabel(Label label) {
    Label lineLabel = Label.of(Location.none);
    for (int i = 0; i < 2; i++) {
      lineLabel.setLocation(i, label.getLocation(i));
    }
    return lineLabel;
  }

  Array<TopologyLocation?> elt = Array(2);

  Label(Label lbl) {
    elt[0] = TopologyLocation(lbl.elt[0]!);
    elt[1] = TopologyLocation(lbl.elt[1]!);
  }

  Label.of(int onLoc) {
    elt[0] = TopologyLocation.of(onLoc);
    elt[1] = TopologyLocation.of(onLoc);
  }

  Label.of2(int geomIndex, int onLoc) {
    elt[0] = TopologyLocation.of(Location.none);
    elt[1] = TopologyLocation.of(Location.none);
    elt[geomIndex]!.setLocation(onLoc);
  }

  Label.of3(int onLoc, int leftLoc, int rightLoc) {
    elt[0] = TopologyLocation.of3(onLoc, leftLoc, rightLoc);
    elt[1] = TopologyLocation.of3(onLoc, leftLoc, rightLoc);
  }

  Label.of4(int geomIndex, int onLoc, int leftLoc, int rightLoc) {
    elt[0] = TopologyLocation.of3(Location.none, Location.none, Location.none);
    elt[1] = TopologyLocation.of3(Location.none, Location.none, Location.none);
    elt[geomIndex]!.setLocations(onLoc, leftLoc, rightLoc);
  }

  void flip() {
    elt[0]!.flip();
    elt[1]!.flip();
  }

  int getLocation2(int geomIndex, int posIndex) {
    return elt[geomIndex]!.get(posIndex);
  }

  int getLocation(int geomIndex) {
    return elt[geomIndex]!.get(Position.on);
  }

  void setLocation2(int geomIndex, int posIndex, int location) {
    elt[geomIndex]!.setLocation2(posIndex, location);
  }

  void setLocation(int geomIndex, int location) {
    elt[geomIndex]!.setLocation2(Position.on, location);
  }

  void setAllLocations(int geomIndex, int location) {
    elt[geomIndex]!.setAllLocations(location);
  }

  void setAllLocationsIfNull2(int geomIndex, int location) {
    elt[geomIndex]!.setAllLocationsIfNull(location);
  }

  void setAllLocationsIfNull(int location) {
    setAllLocationsIfNull2(0, location);
    setAllLocationsIfNull2(1, location);
  }

  void merge(Label lbl) {
    for (int i = 0; i < 2; i++) {
      if ((elt[i] == null) && (lbl.elt[i] != null)) {
        elt[i] = TopologyLocation(lbl.elt[i]!);
      } else {
        elt[i]!.merge(lbl.elt[i]!);
      }
    }
  }

  int getGeometryCount() {
    int count = 0;
    if (!elt[0]!.isNull()) {
      count++;
    }

    if (!elt[1]!.isNull()) {
      count++;
    }

    return count;
  }

  bool isNull(int geomIndex) {
    return elt[geomIndex]!.isNull();
  }

  bool isAnyNull(int geomIndex) {
    return elt[geomIndex]!.isAnyNull();
  }

  bool isArea() {
    return elt[0]!.isArea() || elt[1]!.isArea();
  }

  bool isArea2(int geomIndex) {
    return elt[geomIndex]!.isArea();
  }

  bool isLine(int geomIndex) {
    return elt[geomIndex]!.isLine();
  }

  bool isEqualOnSide(Label lbl, int side) {
    return elt[0]!.isEqualOnSide(lbl.elt[0]!, side) &&
        elt[1]!.isEqualOnSide(lbl.elt[1]!, side);
  }

  bool allPositionsEqual(int geomIndex, int loc) {
    return elt[geomIndex]!.allPositionsEqual(loc);
  }

  void toLine(int geomIndex) {
    if (elt[geomIndex]!.isArea()) {
      elt[geomIndex] = TopologyLocation.of(elt[geomIndex]!.location[0]);
    }
  }

  @override
  String toString() {
    StringBuffer buf = StringBuffer();
    if (elt[0] != null) {
      buf.write("A:");
      buf.write(elt[0].toString());
    }
    if (elt[1] != null) {
      buf.write(" B:");
      buf.write(elt[1].toString());
    }
    return buf.toString();
  }
}
