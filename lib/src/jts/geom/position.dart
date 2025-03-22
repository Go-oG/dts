final class Position {
  static const int on = 0;

  static const int left = 1;

  static const int right = 2;

  static int opposite(int position) {
    if (position == left) return right;

    if (position == right) return left;

    return position;
  }
}
