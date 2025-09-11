import 'dart:math';

abstract interface class ApplyFun<T, R> {
  R execute(T obj);
}

class CollectionUtil {
  static List<R> transform<T, R>(List<T> coll, ApplyFun<T, R> func) {
    return coll.map((e) => func.execute(e)).toList();
  }

  static void apply<T>(List<T> coll, ApplyFun<T, dynamic> func) {
    coll.map((e) => func.execute(e));
  }

  static List<T> select<T>(List<T> collection, ApplyFun<T, bool> func) {
    return collection.where((e) => func.execute(e)).toList();
  }

  static int binarySearch<T>(List<T> a, int fromIndex, int toIndex, T key) {
    int low = fromIndex;
    int high = toIndex - 1;
    while (low <= high) {
      int mid = (low + high) >>> 1;
      T midVal = a[mid];

      int c = (midVal as Comparable).compareTo(key);
      if (c < 0) {
        low = mid + 1;
      } else if (c > 0) {
        high = mid - 1;
      } else {
        return mid;
      }
    }
    return -(low + 1);
  }

  static List<T> copyOf<T>(List<T> original, int newLength, T fillValue) {
    List<T> copy = List.filled(newLength, fillValue);
    arrayCopy(original, 0, copy, 0, min(original.length, newLength));
    return copy;
  }

  static void arrayCopy<T>(
      List<T> src, int srcPos, List<T> dest, int destPos, int length) {
    if (srcPos < 0 ||
        destPos < 0 ||
        length < 0 ||
        srcPos + length > src.length ||
        destPos + length > dest.length) {
      throw RangeError("Invalid source or destination position or length");
    }
    dest.setRange(destPos, destPos + length, src, srcPos);
  }
}
