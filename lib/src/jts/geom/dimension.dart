 import 'package:d_util/d_util.dart';

class Dimension {
  static const int P = 0;

  static const int L = 1;

  static const int A = 2;

  static const int FALSE = -1;

  static const int TRUE = -2;

  static const int DONTCARE = -3;

  static const String SYM_FALSE = 'F';

  static const String SYM_TRUE = 'T';

  static const String SYM_DONTCARE = '*';

  static const String SYM_P = '0';

  static const String SYM_L = '1';

  static const String SYM_A = '2';

  static String toDimensionSymbol(int dimensionValue) {
    switch (dimensionValue) {
      case FALSE:
        return SYM_FALSE;
      case TRUE:
        return SYM_TRUE;
      case DONTCARE:
        return SYM_DONTCARE;
      case P:
        return SYM_P;
      case L:
        return SYM_L;
      case A:
        return SYM_A;
    }
    throw IllegalArgumentException("Unknown dimension value: $dimensionValue");
  }

  static int toDimensionValue(String dimensionSymbol) {
    switch (dimensionSymbol.toUpperCase()) {
      case SYM_FALSE:
        return FALSE;
      case SYM_TRUE:
        return TRUE;
      case SYM_DONTCARE:
        return DONTCARE;
      case SYM_P:
        return P;
      case SYM_L:
        return L;
      case SYM_A:
        return A;
    }
    throw IllegalArgumentException("Unknown dimension symbol: $dimensionSymbol");
  }
}
