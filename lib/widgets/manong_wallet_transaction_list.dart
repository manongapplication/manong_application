import 'package:flutter/material.dart';
import 'package:manong_application/models/manong_wallet_transaction.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/widgets/manong_wallet_transaction_card.dart';

class ManongWalletTransactionList extends StatelessWidget {
  final List<ManongWalletTransaction> transactions;
  final bool showHeader;
  final int maxItems;
  final String? title;
  final bool sortByCreatedAt;

  const ManongWalletTransactionList({
    super.key,
    required this.transactions,
    this.showHeader = true,
    this.maxItems = 3,
    this.title,
    this.sortByCreatedAt = true,
  });

  List<ManongWalletTransaction> get _sortedTransactions {
    if (!sortByCreatedAt) return transactions;

    // Sort by createdAt in descending order (newest first)
    final sorted = List<ManongWalletTransaction>.from(transactions)
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1900);
        final bDate = b.createdAt ?? DateTime(1900);
        return bDate.compareTo(aDate); // Descending order (newest first)
      });
    return sorted;
  }

  void _showFullTransactionList(BuildContext context) {
    final sortedTransactions = _sortedTransactions;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title ?? 'All Wallet Transactions',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (sortedTransactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Sorted by: Newest first',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: sortedTransactions.isEmpty
                  ? const Center(child: Text('No transactions found'))
                  : ListView.builder(
                      itemCount: sortedTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = sortedTransactions[index];
                        return ManongWalletTransactionCard(
                          manongWalletTransaction: transaction,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedTransactions = _sortedTransactions;

    if (sortedTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayTransactions = maxItems > 0
        ? sortedTransactions.take(maxItems).toList()
        : sortedTransactions;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title ?? 'Wallet Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (maxItems > 0 && sortedTransactions.length > maxItems)
                  TextButton(
                    onPressed: () => _showFullTransactionList(context),
                    child: Text(
                      'View All (${sortedTransactions.length})',
                      style: TextStyle(
                        color: AppColorScheme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Transaction cards
          ...displayTransactions.map(
            (transaction) => ManongWalletTransactionCard(
              manongWalletTransaction: transaction,
            ),
          ),

          // Show more button if there are more transactions
          if (maxItems > 0 && sortedTransactions.length > maxItems)
            Center(
              child: TextButton(
                onPressed: () => _showFullTransactionList(context),
                child: Text(
                  'Show ${sortedTransactions.length - maxItems} more transactions',
                  style: TextStyle(color: AppColorScheme.primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
