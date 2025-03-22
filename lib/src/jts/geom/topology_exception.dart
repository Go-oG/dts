import 'coordinate.dart';

class TopologyException {
  static String msgWithCoord(String msg, [Coordinate? pt]) {
    if (pt != null) return "$msg [ $pt ]";

    return msg;
  }

  late final String message;
  Coordinate? _pt;

  TopologyException(String msg, [Coordinate? pt]) {
    message = (msgWithCoord(msg, pt));
    if(pt!=null){
      _pt = Coordinate.of(pt);
    }

  }

  Coordinate? getCoordinate() {
    return _pt;
  }
}
