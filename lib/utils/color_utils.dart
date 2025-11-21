import 'package:flutter/material.dart';

Color colorFromHex(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

// Status color mapper
Color getStatusColor(String? status) {
  switch (status?.toLowerCase()) {
    // Service Request statuses
    case 'pending':
      return Colors.orange;
    case 'accepted':
      return Colors.blue;
    case 'completed':
      return Colors.green;
    case 'expired':
    case 'cancelled':
      return Colors.red;
    case 'available':
      return Colors.greenAccent;
    case 'unavailable':
      return Colors.grey;

    // Payment statuses
    case 'unpaid':
      return Colors.redAccent;
    case 'paid':
      return Colors.green;
    case 'failed':
      return Colors.red;
    case 'refunding':
      return Colors.purpleAccent;
    case 'refunded':
      return Colors.purple;

    // Refund statuses
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    case 'pending': // Refund pending (already exists for service request)
      return Colors.orange;

    default:
      return Colors.grey;
  }
}

// Border color mapper
Color getStatusBorderColor(String? status) {
  switch (status?.toLowerCase()) {
    // Service Request statuses
    case 'pending':
      return Colors.orange.shade700;
    case 'accepted':
      return Colors.blue.shade700;
    case 'completed':
      return Colors.green.shade700;
    case 'expired':
    case 'cancelled':
      return Colors.red.shade700;
    case 'available':
      return Colors.green.shade700;
    case 'unavailable':
      return Colors.grey.shade700;

    // Payment statuses
    case 'unpaid':
      return Colors.red.shade700;
    case 'paid':
      return Colors.green.shade700;
    case 'failed':
      return Colors.red.shade900;
    case 'refunding':
      return Colors.purple.shade400;
    case 'refunded':
      return Colors.purple.shade700;

    // Refund statuses
    case 'approved':
      return Colors.green.shade700;
    case 'rejected':
      return Colors.red.shade700;

    default:
      return Colors.grey.shade700;
  }
}
