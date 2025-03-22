final class Location {
  static const int interior = 0;

  static const int boundary = 1;

  static const int exterior = 2;

  static const int none = -1;

  static String toLocationSymbol(int locationValue) {
    switch (locationValue) {
      case exterior:
        return 'e';
      case boundary:
        return 'b';
      case interior:
        return 'i';
      case none:
        return '-';
    }
    throw ("Unknown location value: $locationValue");
  }
}
