import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class EmptyStateWidget extends StatelessWidget {
  final String searchQuery;
  final String emptyMessage;
  final VoidCallback? onPressed;
  final VoidCallback? onRefresh;

  const EmptyStateWidget({
    super.key,
    required this.searchQuery,
    this.emptyMessage = "No results found",
    this.onPressed,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isEmpty ? Icons.inbox_outlined : Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? emptyMessage
                : 'No results found for "$searchQuery"',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onPressed,
              child: const Text(
                'Clear search',
                style: TextStyle(color: AppColorScheme.primaryColor),
              ),
            ),
          ],

          if (onRefresh != null) ...[
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColorScheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: onRefresh,
              child: Text('Refresh'),
            ),
          ],
        ],
      ),
    );
  }
}
