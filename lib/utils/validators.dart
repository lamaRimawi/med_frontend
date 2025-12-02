class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Remove whitespace
    value = value.trim();
    
    // Basic email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    value = value.trim();
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    // Allow letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  // Password validation with strength checking
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 10) {
      return 'Password must be at least 10 characters';
    }
    
    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }
    
    // Check for uppercase
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter (A-Z)';
    }
    
    // Check for lowercase
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter (a-z)';
    }
    
    // Check for number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number (0-9)';
    }
    
    // Check for special character (expanded set)
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_+=\-\[\]\\\/~`]'))) {
      return 'Password must contain at least one special character (!@#\$%^&*...)';
    }
    
    // Check for common weak patterns
    if (RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)', caseSensitive: false).hasMatch(value)) {
      return 'Password contains common sequential patterns. Please use a stronger password';
    }
    
    // Check for repeated characters (3 or more)
    if (RegExp(r'(.)\1{2,}').hasMatch(value)) {
      return 'Password should not contain repeated characters (e.g., aaa, 111)';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    value = value.trim();
    
    // Remove common formatting characters
    final digitsOnly = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (digitsOnly.length > 15) {
      return 'Phone number must be less than 15 digits';
    }
    
    // Check if it contains only digits (after removing formatting)
    if (!RegExp(r'^[0-9]+$').hasMatch(digitsOnly)) {
      return 'Phone number can only contain digits';
    }
    
    return null;
  }

  // Date of birth validation
  static String? validateDateOfBirth(DateTime? value) {
    if (value == null) {
      return 'Date of birth is required';
    }
    
    final now = DateTime.now();
    final age = now.year - value.year - 
        ((now.month > value.month || 
         (now.month == value.month && now.day >= value.day)) ? 0 : 1);
    
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    
    if (age > 120) {
      return 'Please enter a valid date of birth';
    }
    
    if (value.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }
    
    return null;
  }

  // Verification code validation
  static String? validateVerificationCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Verification code is required';
    }
    
    if (value.length != 6) {
      return 'Verification code must be 6 digits';
    }
    
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'Verification code must contain only digits';
    }
    
    return null;
  }

  // Password strength calculation (0-5)
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    int strength = 0;
    
    // Length check
    if (password.length >= 10) strength++;
    if (password.length >= 14) strength++;
    
    // Character variety
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_+=\-\[\]\\\/~`]'))) strength++;
    
    // Deduct for weak patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) strength = (strength - 1).clamp(0, 5);
    if (RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde|def)', caseSensitive: false).hasMatch(password)) {
      strength = (strength - 1).clamp(0, 5);
    }
    
    // Cap at 5
    return strength > 5 ? 5 : strength;
  }

  // Get password strength label
  static String getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      default:
        return 'Very Weak';
    }
  }

  // Get password strength color
  static int getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 0xFFEF4444; // Red
      case 2:
        return 0xFFF59E0B; // Orange
      case 3:
        return 0xFFFBBF24; // Yellow
      case 4:
        return 0xFF10B981; // Green
      case 5:
        return 0xFF059669; // Dark Green
      default:
        return 0xFFEF4444;
    }
  }
}
