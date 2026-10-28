/// Centralized input validation and sanitization utilities for GymVibe.
///
/// Provides reusable validators for email, password, name, and free-text
/// fields. All validators return `null` on success or an error message string
/// on failure, making them compatible with Flutter's `TextFormField.validator`.
class InputValidators {
  InputValidators._();

  // ─── Email ──────────────────────────────────────────────────────────────────

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates that [value] is a well-formed email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length > 254) {
      return 'Email is too long.';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  // ─── Password ───────────────────────────────────────────────────────────────

  /// Validates password strength.
  ///
  /// Requirements:
  /// - Minimum 8 characters
  /// - At least 1 uppercase letter
  /// - At least 1 lowercase letter
  /// - At least 1 digit
  /// - At least 1 special character (!@#\$%^&*(),.?":{}|<>)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (value.length > 128) {
      return 'Password is too long.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least 1 uppercase letter.';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least 1 lowercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least 1 number.';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least 1 special character.';
    }
    return null;
  }

  /// Returns a password strength label for UI display.
  static String passwordStrengthLabel(String password) {
    if (password.isEmpty) return '';
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) return 'Weak';
    if (score <= 4) return 'Medium';
    return 'Strong';
  }

  // ─── Name ───────────────────────────────────────────────────────────────────

  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s\-'.]+$");

  /// Validates a user's display name.
  ///
  /// Allows letters, spaces, hyphens, apostrophes, and periods.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters.';
    }
    if (trimmed.length > 50) {
      return 'Name must be 50 characters or less.';
    }
    if (!_nameRegex.hasMatch(trimmed)) {
      return 'Name contains invalid characters.';
    }
    return null;
  }

  // ─── Free Text (Reviews, Descriptions) ──────────────────────────────────────

  /// Validates free-form text fields like reviews or descriptions.
  static String? validateFreeText(String? value, {int maxLength = 500, String fieldName = 'Text'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    if (value.trim().length > maxLength) {
      return '$fieldName must be $maxLength characters or less.';
    }
    return null;
  }

  // ─── Confirm Password ──────────────────────────────────────────────────────

  /// Validates that the confirmation matches the original password.
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != originalPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  // ─── Sanitization ──────────────────────────────────────────────────────────

  static final RegExp _htmlTagRegex = RegExp(r'<[^>]*>');
  static final RegExp _scriptRegex = RegExp(
    r'(javascript\s*:)|(on\w+\s*=)',
    caseSensitive: false,
  );

  /// Sanitizes user input by trimming whitespace and stripping HTML/script tags.
  static String sanitize(String input) {
    String sanitized = input.trim();
    sanitized = sanitized.replaceAll(_htmlTagRegex, '');
    sanitized = sanitized.replaceAll(_scriptRegex, '');
    return sanitized;
  }

  // ─── Non-empty (Generic) ───────────────────────────────────────────────────

  /// Simple non-empty check for required fields.
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }
}
