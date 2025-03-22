
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
}
