/// Comprehensive input validation rules for Block Bloom authentication & user profile
class AppValidators {
  AppValidators._();

  /// Validates user display name:
  /// - Non-empty (if required)
  /// - Between 2 and 30 characters
  /// - Only contains valid display characters (letters, numbers, spaces, dots, hyphens, apostrophes)
  static String? validateName(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Please enter your name' : null;
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (trimmed.length > 30) {
      return 'Name cannot exceed 30 characters';
    }
    final nameRegex = RegExp(r"^[\p{L}\p{N} _.'-]+$", unicode: true);
    if (!nameRegex.hasMatch(trimmed)) {
      return 'Name can only contain letters, numbers, spaces, or hyphens';
    }
    return null;
  }

  /// Validates email address with standard RFC-compliant regex:
  /// - Non-empty
  /// - Has valid local part, @, domain name, and TLD (e.g., .com, .org)
  /// - No consecutive dots or leading/trailing whitespace
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final trimmed = value.trim();
    if (trimmed.length > 100) {
      return 'Email address is too long (max 100 characters)';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed) || trimmed.contains('..')) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password:
  /// - Non-empty (if required)
  /// - Cannot be only spaces
  /// - Minimum 6 characters (Firebase Auth requirement)
  /// - Maximum 64 characters
  static String? validatePassword(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Please enter your password' : null;
    }
    if (value.trim().isEmpty) {
      return 'Password cannot contain only spaces';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (value.length > 64) {
      return 'Password cannot exceed 64 characters';
    }
    return null;
  }

  /// Validates confirmation password against the original password:
  /// - Must not be empty if original password is provided
  /// - Must exactly match original password
  static String? validateConfirmPassword(
    String? value,
    String? originalPassword, {
    bool isRequired = true,
  }) {
    final hasOriginal = originalPassword != null && originalPassword.isNotEmpty;
    if (value == null || value.isEmpty) {
      if (isRequired || hasOriginal) {
        return 'Please confirm your password';
      }
      return null;
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates 4-digit numeric OTP / confirmation code
  static String? validateOtp(String? value, {int expectedLength = 4}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the $expectedLength-digit code';
    }
    final trimmed = value.trim();
    if (trimmed.length != expectedLength) {
      return 'Please enter all $expectedLength digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Code must contain numbers only';
    }
    return null;
  }
}
