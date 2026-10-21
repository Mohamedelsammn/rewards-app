/// Client-side checks that mirror the server rules so users get feedback
/// before a request is sent. The server remains authoritative.
class Validators {
  const Validators._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool email(String value) => _email.hasMatch(value.trim());

  static String normalizeEmail(String value) => value.trim().toLowerCase();

  /// Server accepts 8–128 characters.
  static bool passwordLength(String value) => value.length >= 8 && value.length <= 128;

  static bool passwordHasLettersAndNumbers(String value) =>
      RegExp(r'[A-Za-z]').hasMatch(value) && RegExp(r'\d').hasMatch(value);

  /// The redesign's "strong password" rule: 10+ characters with uppercase,
  /// lowercase and digits.
  static bool passwordIsStrong(String value) =>
      value.length >= 10 &&
      RegExp(r'[a-z]').hasMatch(value) &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value);

  static bool passwordAcceptable(String value) =>
      passwordLength(value) && passwordHasLettersAndNumbers(value) && passwordIsStrong(value);

  static bool otp(String value) => RegExp(r'^\d{6}$').hasMatch(value);

  /// Display name: 2–60 characters (server rule for `name`).
  static bool displayName(String value) {
    final length = value.trim().length;
    return length >= 2 && length <= 60;
  }
}
