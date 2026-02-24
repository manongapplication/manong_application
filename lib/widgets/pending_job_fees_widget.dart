import 'package:flutter/material.dart';
import 'package:manong_application/models/manong_wallet_transaction.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/widgets/manong_wallet_transaction_list.dart';

class PendingJobFeesWidget extends StatelessWidget {
  final int pendingCount;
  final double totalAmount;
  final List<ManongWalletTransaction>? pendingJobFees;

  const PendingJobFeesWidget({
    super.key,
    required this.pendingCount,
    required this.totalAmount,
    required this.pendingJobFees,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message with count + total amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have $pendingCount pending job ${pendingCount == 1 ? 'fee' : 'fees'} totaling \$${totalAmount.toStringAsFixed(2)}. '
                      'Please settle ${pendingCount == 1 ? 'this' : 'these'} to proceed with cash out.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // List of pending job fees
            Text(
              'Pending Job Fees:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColorScheme.primaryDark,
              ),
            ),

            const SizedBox(height: 8),

            // Transaction list
            if (pendingJobFees != null)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ManongWalletTransactionList(
                  transactions: pendingJobFees!,
                  showHeader: false,
                  maxItems: pendingJobFees!.length,
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
