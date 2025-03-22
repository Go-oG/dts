import 'dart:math' as math;

///一种快速的选择算法，来源于快速排序
///移植自 https://github.com/mourner/quickselect
///重新排列项目，使Array中的所有在[left, k]的数据都是最小的。第K个元素的索引为[left, right]中的 (k - left + 1)。
/// array ：要部分排序的数组（就地）
/// k ：用于部分排序的中间索引（如上定义）
/// left ：要排序的范围的左索引（默认 0 ）
/// right ：右索引（默认情况下是数组的最后一个索引）
/// compareFn ：比较函数
/// example
/// var arr = [65, 28, 59, 33, 21, 56, 22, 95, 50, 12, 90, 53, 28, 77, 39];
/// quickselect(arr, 8);
/// arr is [39, 28, 28, 33, 21, 12, 22, 50, 53, 56, 59, 65, 90, 77, 95]
///                                         ^^ middle index
void fastSelect<T>(List<T> arr, int k, [int left = 0, int? right, int Function(T a, T b)? compare]) {
  if (left < 0) {
    left = 0;
  }
  right ??= arr.length - 1;
  compare ??= _defaultCompare;
  _fastSelectStep(arr, k, left, right, compare);
}

_fastSelectStep<T>(List<T> arr, int k, int left, int right, int Function(T a, T b) compare) {
  while (right > left) {
    if (right - left > 600) {
      int n = right - left + 1;
      int m = k - left + 1;
      double z = math.log(n);
      double s = 0.5 * math.exp(2 * z / 3);
      double sd = 0.5 * math.sqrt(z * s * (n - s) / n) * (m - n / 2 < 0 ? -1 : 1);
      int newLeft = math.max(left, (k - m * s / n + sd).floor());
      int newRight = math.min(right, (k + (n - m) * s / n + sd).floor());
      _fastSelectStep(arr, k, newLeft, newRight, compare);
    }

    var t = arr[k];
    var i = left;
    var j = right;

    _swap(arr, left, k);
    if (compare(arr[right], t) > 0) _swap(arr, left, right);

    while (i < j) {
      _swap(arr, i, j);
      i++;
      j--;
      while (compare(arr[i], t) < 0) {
        i++;
      }
      while (compare(arr[j], t) > 0) {
        j--;
      }
    }

    if (compare(arr[left], t) == 0) {
      _swap(arr, left, j);
    } else {
      j++;
      _swap(arr, j, right);
    }
    if (j <= k) left = j + 1;
    if (k <= j) right = j - 1;
  }
}

void _swap<T>(List<T> arr, int i, int j) {
  var tmp = arr[i];
  arr[i] = arr[j];
  arr[j] = tmp;
}

int _defaultCompare<T>(T a, T b) {
  if (a is Comparable) {
    return a.compareTo(b);
  }
  if (a is num) {
    var t = b as num;
    return a < b
        ? -1
        : a > b
        ? 1
        : 0;
  }

  var a1 = a.hashCode;
  var b2 = b.hashCode;
  return a1 < b2
      ? -1
      : a1 > b2
      ? 1
      : 0;
}