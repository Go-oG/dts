import 'dart:math';

import 'package:d_util/d_util.dart';

class QuickSelect<T> {
  static final random = Random();
  late List<T?> list;
  late List<T?> temp;
  CompareFun<T> compareFun;

  QuickSelect(List<T> this.list, this.compareFun) {
    temp = List.filled(list.length, null);
  }

  int findIndex(T value) {
    int tempLength = list.length;
    int length = tempLength;
    T pivot = list[0] as T;
    while (length > 0) {
      length = tempLength;
      pivot = list[random.nextInt(length)] as T;
      tempLength = 0;
      for (int i = 0; i < length; i++) {
        T iValue = list[i] as T;
        if (value == iValue) {
          return i;
        } else if (compareFun(value, pivot) > 0 &&
            compareFun(iValue, pivot) > 0) {
          temp[tempLength++] = iValue;
        } else if (compareFun(value, pivot) < 0 &&
            compareFun(iValue, pivot) < 0) {
          temp[tempLength++] = iValue;
        }
      }
      list = temp;
      length = tempLength;
    }
    return -1;
  }

  static int quickFindIndex<T>(
      List<T> list, T value, CompareFun<T> compareFun) {
    return QuickSelect(list, compareFun).findIndex(value);
  }
}
