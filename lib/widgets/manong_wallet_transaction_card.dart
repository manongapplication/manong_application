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
      case WalletTransactionType.earning:
        return Colors.lightGreen;
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
      case WalletTransactionType.earning:
        return Icons.arrow_upward_rounded;
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
      case WalletTransactionType.earning:
        return 'Earning';
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

  String? _getProviderOrBankDisplayText() {
    final metadata = manongWalletTransaction.metadata;
    if (metadata == null) return null;

    if (metadata['provider'] != null &&
        metadata['provider'].toString().isNotEmpty &&
        metadata['provider'].toString().toLowerCase() != 'null') {
      return metadata['provider'].toString();
    }

    if (metadata['bankCode'] != null &&
        metadata['bankCode'].toString().isNotEmpty &&
        metadata['bankCode'].toString().toLowerCase() != 'null') {
      return metadata['bankCode'].toString();
    }

    if (metadata['bankName'] != null &&
        metadata['bankName'].toString().isNotEmpty &&
        metadata['bankName'].toString().toLowerCase() != 'null') {
      return metadata['bankName'].toString();
    }

    return null;
  }

  IconData? _getProviderOrBankIcon(String? displayText) {
    if (displayText == null) return null;

    final text = displayText.toLowerCase();

    if (text.contains('gcash')) {
      return Icons.phone_android;
    } else if (text.contains('maya') || text.contains('paymaya')) {
      return Icons.credit_card;
    } else if (text.contains('bank') ||
        text.contains('bpi') ||
        text.contains('bdo') ||
        text.contains('metrobank') ||
        text.contains('landbank') ||
        text.contains('unionbank') ||
        text.contains('security') ||
        text.contains('rcbc') ||
        text.contains('china') ||
        text.contains('pnb') ||
        text.contains('ubp') ||
        text.contains('mbtc') ||
        text.contains('lbp') ||
        text.contains('sbc') ||
        text.contains('cbc')) {
      return Icons.account_balance;
    }

    return Icons.payment;
  }

  bool _shouldShowAccountDetails() {
    return manongWalletTransaction.type == WalletTransactionType.payout &&
        manongWalletTransaction.metadata != null &&
        (manongWalletTransaction.metadata!['accountName'] != null ||
            manongWalletTransaction.metadata!['accountNumber'] != null);
  }

  String _formatAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.isEmpty) return '';

    if (accountNumber.length <= 4) {
      return '****$accountNumber';
    }

    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final isPositive =
        manongWalletTransaction.type == WalletTransactionType.topup;
    final typeColor = _getTypeColor(manongWalletTransaction.type);

    final providerOrBankText = _getProviderOrBankDisplayText();
    final providerOrBankIcon = _getProviderOrBankIcon(providerOrBankText);

    final showAccountDetails = _shouldShowAccountDetails();
    final accountName = manongWalletTransaction.metadata?['accountName']
        ?.toString();
    final accountNumber = manongWalletTransaction.metadata?['accountNumber']
        ?.toString();
    final formattedAccountNumber = _formatAccountNumber(accountNumber);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon, type and amount
            Row(
              children: [
                // Icon with gradient background
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [typeColor, typeColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(manongWalletTransaction.type),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Type and amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeDisplayName(manongWalletTransaction.type),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(manongWalletTransaction.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                PriceTag(
                  price: manongWalletTransaction.amount,
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isPositive
                        ? Colors.green
                        : AppColorScheme.primaryDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Status and provider chips row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      manongWalletTransaction.status,
                    ).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(
                        manongWalletTransaction.status,
                      ).withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        manongWalletTransaction.status ==
                                WalletTransactionStatus.completed
                            ? Icons.check_circle_rounded
                            : manongWalletTransaction.status ==
                                  WalletTransactionStatus.pending
                            ? Icons.hourglass_empty_rounded
                            : Icons.error_outline_rounded,
                        size: 12,
                        color: _getStatusColor(manongWalletTransaction.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        manongWalletTransaction.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(
                            manongWalletTransaction.status,
                          ),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Provider/Bank chip
                if (providerOrBankText != null && providerOrBankIcon != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(providerOrBankIcon, size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          providerOrBankText.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Account details section (for payouts)
            if (showAccountDetails) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (accountName != null && accountName.isNotEmpty) ...[
                      Text(
                        'ACCOUNT NAME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        accountName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (formattedAccountNumber.isNotEmpty) ...[
                      Text(
                        'ACCOUNT NUMBER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedAccountNumber,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Description (if exists)
            if (manongWalletTransaction.description != null &&
                manongWalletTransaction.description!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        manongWalletTransaction.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
