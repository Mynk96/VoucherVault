import 'package:flutter/material.dart';

class Validators {
  /// Validates that a field is not empty
  static String? validateRequired(String? value, String errorMessage) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage;
    }
    return null;
  }

  /// Validates that a field contains a valid numerical value
  static String? validateNumber(String? value, String errorMessage) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    if (double.tryParse(value) == null) {
      return errorMessage;
    }
    
    return null;
  }

  /// Validates that a field contains a positive number
  static String? validatePositiveNumber(String? value, String errorMessage) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return errorMessage;
    }
    
    if (number <= 0) {
      return 'Please enter a positive number';
    }
    
    return null;
  }

  /// Validates the maximum length of a field
  static String? validateMaxLength(String? value, int maxLength, String errorMessage) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    if (value.length > maxLength) {
      return errorMessage;
    }
    
    return null;
  }

  /// Validates that a string is a valid date format
  static String? validateDate(String? value, String errorMessage) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    
    // Simple validation for MM/DD/YYYY format
    final RegExp dateRegex = RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$');
    if (!dateRegex.hasMatch(value)) {
      return errorMessage;
    }
    
    // Further validation to check if it's a valid date
    try {
      final parts = value.split('/');
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      if (month < 1 || month > 12) {
        return 'Invalid month';
      }
      
      if (day < 1 || day > 31) {
        return 'Invalid day';
      }
      
      // Check for specific month lengths
      if ((month == 4 || month == 6 || month == 9 || month == 11) && day > 30) {
        return 'This month has only 30 days';
      }
      
      // Check for February
      if (month == 2) {
        final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
        if (day > (isLeapYear ? 29 : 28)) {
          return isLeapYear 
              ? 'February has only 29 days in a leap year' 
              : 'February has only 28 days in this year';
        }
      }
      
      return null;
    } catch (e) {
      return errorMessage;
    }
  }

  /// Validates a future date
  static String? validateFutureDate(DateTime? value, String errorMessage) {
    if (value == null) {
      return errorMessage;
    }
    
    if (value.isBefore(DateTime.now())) {
      return 'Please select a future date';
    }
    
    return null;
  }

  /// Validates a code format (alphanumeric with some special characters)
  static String? validateVoucherCode(String? value, String errorMessage) {
    if (value == null || value.isEmpty) {
      return errorMessage;
    }
    
    // Voucher codes typically consist of letters, numbers, and sometimes hyphens or underscores
    final RegExp codeRegex = RegExp(r'^[a-zA-Z0-9_\-]+$');
    if (!codeRegex.hasMatch(value)) {
      return 'Code can only contain letters, numbers, hyphens, and underscores';
    }
    
    return null;
  }

  /// Validates all fields in a form together
  static bool validateForm(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }
}
