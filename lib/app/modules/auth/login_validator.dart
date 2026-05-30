/// Pure, synchronous validation for the administrator login form
/// (Requirement 1.6).
///
/// Each `validate*` method returns `null` when the field is valid and a
/// per-field, human-readable message when it is invalid, so the
/// `LoginController` can surface an inline message beneath each field and
/// withhold the authentication request while any field is invalid.
///
/// The rules:
/// * Email — required, well-formed, and at most 254 characters.
/// * Password — required (non-empty).
///
/// All methods are static and side-effect free so they can be reused by the
/// controller and exercised in isolation.
class LoginValidator {
  const LoginValidator._();

  /// The maximum allowed email length. An email longer than this is rejected
  /// (Requirement 1.6: "over-254-character email").
  static const int maxEmailLength = 254;

  /// Message shown when the email field is left empty.
  static const String emailRequiredMessage = 'Email is required.';

  /// Message shown when the email exceeds [maxEmailLength] characters.
  static const String emailTooLongMessage =
      'Email must be $maxEmailLength characters or fewer.';

  /// Message shown when the email is not a well-formed address.
  static const String emailInvalidMessage = 'Enter a valid email address.';

  /// Message shown when the password field is left empty.
  static const String passwordRequiredMessage = 'Password is required.';

  /// HTML5-style email pattern: a widely used, pragmatic address grammar that
  /// accepts the common local-part characters and a dotted domain while
  /// rejecting malformed inputs (missing `@`, missing domain, spaces, etc.).
  static final RegExp _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+"
    r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  /// Validates [email], returning `null` when it is valid.
  ///
  /// Invalid (in priority order) when it is empty, longer than
  /// [maxEmailLength] characters, or not a well-formed address. The checks are
  /// ordered so the most specific actionable message is returned first.
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return emailRequiredMessage;
    }
    if (email.length > maxEmailLength) {
      return emailTooLongMessage;
    }
    if (!_emailPattern.hasMatch(email)) {
      return emailInvalidMessage;
    }
    return null;
  }

  /// Validates [password], returning `null` when it is valid.
  ///
  /// Invalid only when empty.
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return passwordRequiredMessage;
    }
    return null;
  }

  /// Whether both [email] and [password] are valid.
  ///
  /// Used to gate the submit control and to decide whether the authentication
  /// request may be issued (Requirement 1.6).
  static bool isFormValid(String email, String password) {
    return validateEmail(email) == null && validatePassword(password) == null;
  }
}
