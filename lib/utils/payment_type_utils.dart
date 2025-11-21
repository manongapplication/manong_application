import 'package:flutter/material.dart';
import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/transaction_type.dart';

class PaymentTypeUtils {
  static Color color(TransactionType type, PaymentStatus status) {
    // Handle pending status first
    if (status == PaymentStatus.pending) {
      return Colors.orange.shade800;
    }

    switch (type) {
      case TransactionType.payment:
        return Colors.green.shade800;
      case TransactionType.refund:
        return Colors.red.shade800;
      case TransactionType.adjustment:
        return Colors.orange.shade800;
    }
  }

  static Color bgColor(TransactionType type, PaymentStatus status) {
    // Handle pending status first
    if (status == PaymentStatus.pending) {
      return Colors.orange.shade100;
    }

    switch (type) {
      case TransactionType.payment:
        return Colors.green.shade100;
      case TransactionType.refund:
        return Colors.red.shade100;
      case TransactionType.adjustment:
        return Colors.orange.shade100;
    }
  }
}
