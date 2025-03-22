import 'assertion_failed_exception.dart';

class Assert {
  static void isTrue(bool assertion) {
    isTrue2(assertion, null);
  }

  static void isTrue2(bool assertion, String? message) {
    if (!assertion) {
      if (message == null) {
        throw AssertionFailedException();
      } else {
        throw AssertionFailedException(message);
      }
    }
  }

  static void equals(Object expectedValue, Object actualValue) {
    equals2(expectedValue, actualValue, null);
  }

  static void equals2(Object expectedValue, Object actualValue, String? message) {
    if (actualValue != expectedValue) {
      throw AssertionFailedException(
        "Expected $expectedValue but encountered $actualValue ${message != null ? ": $message" : ""}",
      );
    }
  }

  static void shouldNeverReachHere() {
    shouldNeverReachHere2(null);
  }

  static void shouldNeverReachHere2(String? message) {
    throw AssertionFailedException("Should never reach here${message != null ? ": $message" : ""}");
  }
}
