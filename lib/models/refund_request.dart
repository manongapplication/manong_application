import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/refund_status.dart';

class RefundRequest {
  final int id;
  final int serviceRequestId;
  final int userId;
  final int? paymentTransactionId;
  final String reason;
  final String? evidenceUrl;
  final double? amount;
  final RefundStatus status;
  final bool handledManually;
  final int? reviewedBy;
  final String? remarks;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? availableAt;

  final AppUser? reviewedByUser;

  RefundRequest({
    required this.id,
    required this.serviceRequestId,
    required this.userId,
    this.paymentTransactionId,
    required this.reason,
    this.evidenceUrl,
    this.amount,
    required this.status,
    required this.handledManually,
    this.reviewedBy,
    this.remarks,

    this.createdAt,
    this.updatedAt,
    this.availableAt,

    this.reviewedByUser,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    return RefundRequest(
      id: json['id'],
      serviceRequestId: json['serviceRequestId'],
      userId: json['userId'],
      paymentTransactionId: json['paymentTransactionId'],
      reason: json['reason'],
      evidenceUrl: json['evidenceUrl'],
      amount: json['amount'] != null ? double.tryParse(json['amount']) : null,
      status: RefundStatus.values.firstWhere(
        (e) => e.name == json['status'].toString(),
        orElse: () => RefundStatus.pending,
      ),
      handledManually: json['handledManually'],
      reviewedBy: json['reviewedBy'],
      remarks: json['remarks'],

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,

      availableAt: json['availableAt'] != null
          ? DateTime.parse(json['availableAt'].toString())
          : null,

      reviewedByUser: json['reviewedByUser'] != null
          ? AppUser.fromJson(json['reviewedByUser'] as Map<String, dynamic>)
          : null,
    );
  }
}
