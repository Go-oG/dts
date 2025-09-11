class Dimension {
  static const int P = 0;

  static const int L = 1;

  static const int A = 2;

  static const int kFalse = -1;

  static const int kTrue = -2;

  static const int kDontCare = -3;

  static const String symFalse = 'F';

  static const String symTrue = 'T';

  static const String sumDontCare = '*';

  static const String symP = '0';

  static const String sumL = '1';

  static const String sumA = '2';

  static String toDimensionSymbol(int dimensionValue) {
    switch (dimensionValue) {
      case kFalse:
        return symFalse;
      case kTrue:
        return symTrue;
      case kDontCare:
        return sumDontCare;
      case P:
        return symP;
      case L:
        return sumL;
      case A:
        return sumA;
    }
    throw ArgumentError("Unknown dimension value: $dimensionValue");
  }

  static int toDimensionValue(String dimensionSymbol) {
    switch (dimensionSymbol.toUpperCase()) {
      case symFalse:
        return kFalse;
      case symTrue:
        return kTrue;
      case sumDontCare:
        return kDontCare;
      case symP:
        return P;
      case sumL:
        return L;
      case sumA:
        return A;
    }
    throw ArgumentError("Unknown dimension symbol: $dimensionSymbol");
  }
}
