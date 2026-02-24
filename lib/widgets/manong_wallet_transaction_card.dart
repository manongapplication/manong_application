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

  // Helper method to get the display text for provider/bank
  String? _getProviderOrBankDisplayText() {
    final metadata = manongWalletTransaction.metadata;

    if (metadata == null) return null;

    // Check if provider exists and is not empty
    if (metadata['provider'] != null &&
        metadata['provider'].toString().isNotEmpty &&
        metadata['provider'].toString().toLowerCase() != 'null') {
      return metadata['provider'].toString();
    }

    // If provider is empty, check for bank code
    if (metadata['bankCode'] != null &&
        metadata['bankCode'].toString().isNotEmpty &&
        metadata['bankCode'].toString().toLowerCase() != 'null') {
      return metadata['bankCode'].toString();
    }

    // If bank code is empty, check for bank name
    if (metadata['bankName'] != null &&
        metadata['bankName'].toString().isNotEmpty &&
        metadata['bankName'].toString().toLowerCase() != 'null') {
      return metadata['bankName'].toString();
    }

    // Return null if none found
    return null;
  }

  // Helper method to get icon for provider/bank
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

  // Helper method to check if we should show account details (for payouts)
  bool _shouldShowAccountDetails() {
    return manongWalletTransaction.type == WalletTransactionType.payout &&
        manongWalletTransaction.metadata != null &&
        (manongWalletTransaction.metadata!['accountName'] != null ||
            manongWalletTransaction.metadata!['accountNumber'] != null);
  }

  // Helper method to format account number (hide some digits for privacy)
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

    // Get the display text for provider/bank
    final providerOrBankText = _getProviderOrBankDisplayText();
    final providerOrBankIcon = _getProviderOrBankIcon(providerOrBankText);

    // Check if we should show account details
    final showAccountDetails = _shouldShowAccountDetails();
    final accountName = manongWalletTransaction.metadata?['accountName']
        ?.toString();
    final accountNumber = manongWalletTransaction.metadata?['accountNumber']
        ?.toString();
    final formattedAccountNumber = _formatAccountNumber(accountNumber);

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

            // Second row: Status, provider/bank, and date
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

                // Show provider/bank chip if available
                if (providerOrBankText != null &&
                    providerOrBankIcon != null) ...[
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
                        Icon(providerOrBankIcon, size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          providerOrBankText.toUpperCase(),
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

            // Account details section (for payouts)
            if (showAccountDetails) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (accountName != null && accountName.isNotEmpty) ...[
                      Text(
                        'Account: $accountName',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (formattedAccountNumber.isNotEmpty) ...[
                      Text(
                        'Number: $formattedAccountNumber',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ],

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
