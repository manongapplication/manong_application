import 'dart:convert';

import 'package:manong_application/models/wallet_transaction_status.dart';
import 'package:manong_application/models/wallet_transaction_type.dart';

class ManongWalletTransaction {
  final int id;
  final int walletId;
  final WalletTransactionType type;
  final WalletTransactionStatus status;
  final double amount;
  final String currency;
  final String? description;
  final Map<String, dynamic>? metadata;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  ManongWalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    this.description,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory ManongWalletTransaction.fromJson(Map<String, dynamic> json) {
    return ManongWalletTransaction(
      id: json['id'],
      walletId: json['walletId'],
      type: WalletTransactionType.values.firstWhere(
        (e) => e.name == json['status'].toString(),
        orElse: () => WalletTransactionType.topup,
      ),
      status: WalletTransactionStatus.values.firstWhere(
        (e) => e.name == json['status'].toString(),
        orElse: () => WalletTransactionStatus.pending,
      ),
      amount: json['amount'] is String
          ? double.parse(json['amount'])
          : (json['amount'] as num).toDouble(),
      currency: json['currency'],
      description: json['description'],
      metadata: json['metadata'] != null ? jsonDecode(json['metadata']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }
}
