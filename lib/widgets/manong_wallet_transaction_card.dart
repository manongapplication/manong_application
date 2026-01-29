import 'package:flutter/material.dart';
import 'package:manong_application/models/manong_wallet_transaction.dart';
import 'package:manong_application/models/wallet_transaction_status.dart';
import 'package:manong_application/models/wallet_transaction_type.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/widgets/price_tag.dart';
import 'package:intl/intl.dart';

class ManongWalletTransactionCard extends StatelessWidget {
  final ManongWalletTransaction manongWalletTransaction;
  const ManongWalletTransactionCard({
    super.key,
    required this.manongWalletTransaction,
  });

  Color _getStatusColor(WalletTransactionStatus status) {
    switch (status) {
      case WalletTransactionStatus.pending:
        return Colors.orange;
      case WalletTransactionStatus.completed:
        return Colors.green;
      case WalletTransactionStatus.failed:
        return Colors.red;
      default:
        return AppColorScheme.primaryColor;
    }
  }

  Color _getTypeColor(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.topup:
        return Colors.green;
      case WalletTransactionType.job_fee:
        return Colors.blue;
      case WalletTransactionType.payout:
        return Colors.purple;
      case WalletTransactionType.adjustment:
        return Colors.amber;
      case WalletTransactionType.refund:
        return Colors.teal;
      default:
        return AppColorScheme.primaryColor;
    }
  }

  IconData _getTypeIcon(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.topup:
        return Icons.add_circle_outline;
      case WalletTransactionType.job_fee:
        return Icons.work_outline;
      case WalletTransactionType.payout:
        return Icons.account_balance_wallet;
      case WalletTransactionType.adjustment:
        return Icons.tune;
      case WalletTransactionType.refund:
        return Icons.refresh;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _getTypeDisplayName(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.topup:
        return 'Top Up';
      case WalletTransactionType.job_fee:
        return 'Job Fee';
      case WalletTransactionType.payout:
        return 'Payout';
      case WalletTransactionType.adjustment:
        return 'Adjustment';
      case WalletTransactionType.refund:
        return 'Refund';
      default:
        return type.name.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        if (difference.inMinutes < 1) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive =
        manongWalletTransaction.type == WalletTransactionType.topup;
    final typeColor = _getTypeColor(manongWalletTransaction.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row: Type and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getTypeIcon(manongWalletTransaction.type),
                        color: typeColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getTypeDisplayName(manongWalletTransaction.type),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                PriceTag(price: manongWalletTransaction.amount),
              ],
            ),

            const SizedBox(height: 12),

            // Second row: Status, provider, and date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      manongWalletTransaction.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    manongWalletTransaction.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(manongWalletTransaction.status),
                    ),
                  ),
                ),

                if (manongWalletTransaction.metadata?['provider'] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          manongWalletTransaction.metadata!['provider']!
                                      .toLowerCase() ==
                                  'gcash'
                              ? Icons.phone_android
                              : Icons.credit_card,
                          size: 12,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          manongWalletTransaction.metadata!['provider']!
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                Text(
                  _formatDate(manongWalletTransaction.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),

            // Description (if exists)
            if (manongWalletTransaction.description != null &&
                manongWalletTransaction.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                manongWalletTransaction.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
