class Assert {
  static void isTrue(bool assertion, [String? message]) {
    if (assertion) {
      return;
    }
    throw AssertionFailedException(message ?? "");
  }

  static void equals(Object expectedValue, Object actualValue, [String? message]) {
    if (actualValue != expectedValue) {
      throw AssertionFailedException(
        "Expected $expectedValue but encountered $actualValue ${message != null ? ": $message" : ""}",
      );
    }
  }

  static void shouldNeverReachHere([String? message]) {
    throw AssertionFailedException("Should never reach here${message != null ? ": $message" : ""}");
  }
}

class AssertionFailedException {
  final String message;

  AssertionFailedException([this.message = ""]);
}
