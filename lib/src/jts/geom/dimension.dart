import 'package:d_util/d_util.dart';

class Dimension {
  static const int P = 0;

  static const int L = 1;

  static const int A = 2;

  static const int False = -1;

  static const int True = -2;

  static const int Dontcare = -3;

  static const String symFalse = 'F';

  static const String symTrue = 'T';

  static const String sumDontCare = '*';

  static const String symP = '0';

  static const String sumL = '1';

  static const String sumA = '2';

  static String toDimensionSymbol(int dimensionValue) {
    switch (dimensionValue) {
      case False:
        return symFalse;
      case True:
        return symTrue;
      case Dontcare:
        return sumDontCare;
      case P:
        return symP;
      case L:
        return sumL;
      case A:
        return sumA;
    }
    throw IllegalArgumentException("Unknown dimension value: $dimensionValue");
  }

  static int toDimensionValue(String dimensionSymbol) {
    switch (dimensionSymbol.toUpperCase()) {
      case symFalse:
        return False;
      case symTrue:
        return True;
      case sumDontCare:
        return Dontcare;
      case symP:
        return P;
      case sumL:
        return L;
      case sumA:
        return A;
    }
    throw IllegalArgumentException("Unknown dimension symbol: $dimensionSymbol");
  }
}
