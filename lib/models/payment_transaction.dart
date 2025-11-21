import 'dart:convert';
import 'package:manong_application/models/payment_status.dart';
import 'package:manong_application/models/refund_request.dart';
import 'package:manong_application/models/transaction_type.dart';

class PaymentTransaction {
  final int id;
  final int serviceRequestId;
  final int userId;
  final String provider;
  final String? paymentIntentId;
  final String? paymentIdOnGateway;
  final String? refundIdOnGateway;
  final bool handledManually;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final TransactionType type;
  final String? description;
  final Map<String, dynamic>? metadata;

  final RefundRequest? refundRequest;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentTransaction({
    required this.id,
    required this.serviceRequestId,
    required this.userId,
    required this.provider,
    this.paymentIntentId,
    this.paymentIdOnGateway,
    this.refundIdOnGateway,
    required this.handledManually,
    required this.amount,
    required this.currency,
    required this.status,
    required this.type,
    this.description,
    this.metadata,

    this.refundRequest,

    this.createdAt,
    this.updatedAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'],
      serviceRequestId: json['serviceRequestId'], // fix: was json['id']
      userId: json['userId'],
      provider: json['provider'],
      paymentIntentId: json['paymentIntentId'],
      paymentIdOnGateway: json['paymentIdOnGateway'],
      refundIdOnGateway: json['refundIdOnGateway'],
      handledManually: json['handledManually'],
      amount: json['amount'] is String
          ? double.parse(json['amount'])
          : (json['amount'] as num).toDouble(),
      currency: json['currency'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['status']}',
      ),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
      ),
      description: json['description'],
      metadata: json['metadata'] != null
          ? jsonDecode(json['metadata'])
          : null, // decode JSON string to Map

      refundRequest: json['refundRequest'] != null
          ? RefundRequest.fromJson(json['refundRequest'])
          : null,

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }
}
