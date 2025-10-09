import 'dart:convert';
import 'package:logging/logging.dart';

class ErrorHelper {
  static final Logger _logger = Logger('ErrorHelper');

  /// Extracts a user-friendly error message from exception strings
  /// Handles various error formats including JSON responses from APIs
  static String extractErrorMessage(String errorString) {
    try {
      // Look for JSON pattern in the error string
      final jsonStart = errorString.indexOf('{');
      if (jsonStart != -1) {
        final jsonEnd = errorString.lastIndexOf('}') + 1;
        if (jsonEnd > jsonStart) {
          final jsonString = errorString.substring(jsonStart, jsonEnd);

          // Try to parse as JSON
          final Map<String, dynamic> errorData = json.decode(jsonString);

          // Extract message from different possible formats
          if (errorData['message'] != null) {
            if (errorData['message'] is String) {
              return errorData['message'];
            } else if (errorData['message'] is List) {
              // Handle array of messages (validation errors)
              List<String> messages = List<String>.from(errorData['message']);
              return messages.join(', ');
            }
          }

          // Fallback to error field
          if (errorData['error'] != null) {
            return errorData['error'];
          }

          // Fallback to statusCode with message
          if (errorData['statusCode'] != null) {
            return 'Request failed with status ${errorData['statusCode']}';
          }
        }
      }

      // Handle common error patterns
      if (errorString.contains('SocketException')) {
        return 'Network connection error. Please check your internet connection.';
      }

      if (errorString.contains('TimeoutException')) {
        return 'Request timed out. Please try again.';
      }

      if (errorString.contains('FormatException')) {
        return 'Invalid data format received from server.';
      }
    } catch (parseError) {
      // If JSON parsing fails, log the error for debugging
      _logger.warning('Failed to parse error JSON: $parseError');
    }

    // Final fallback: return a user-friendly message
    return 'An unexpected error occurred. Please try again.';
  }

  /// Extracts error message from Exception object
  static String extractErrorMessageFromException(Exception exception) {
    return extractErrorMessage(exception.toString());
  }

  /// Checks if an error string contains validation errors
  static bool isValidationError(String errorString) {
    try {
      final jsonStart = errorString.indexOf('{');
      if (jsonStart != -1) {
        final jsonEnd = errorString.lastIndexOf('}') + 1;
        if (jsonEnd > jsonStart) {
          final jsonString = errorString.substring(jsonStart, jsonEnd);
          final Map<String, dynamic> errorData = json.decode(jsonString);

          return errorData['statusCode'] == 400 && errorData['message'] is List;
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return false;
  }

  /// Gets HTTP status code from error string if available
  static int? getStatusCode(String errorString) {
    try {
      final jsonStart = errorString.indexOf('{');
      if (jsonStart != -1) {
        final jsonEnd = errorString.lastIndexOf('}') + 1;
        if (jsonEnd > jsonStart) {
          final jsonString = errorString.substring(jsonStart, jsonEnd);
          final Map<String, dynamic> errorData = json.decode(jsonString);

          return errorData['statusCode'] as int?;
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }
}
