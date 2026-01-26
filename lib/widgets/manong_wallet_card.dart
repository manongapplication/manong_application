import 'package:flutter/material.dart';
import 'package:manong_application/models/manong_wallet.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/widgets/manong_icon.dart';
import 'package:manong_application/widgets/price_tag.dart';

class ManongWalletCard extends StatelessWidget {
  final ManongWallet? wallet;

  const ManongWalletCard({super.key, this.wallet});

  @override
  Widget build(BuildContext context) {
    // Use empty wallet if null
    final w =
        wallet ??
        ManongWallet(
          id: 0,
          manongId: 0,
          balance: 0.0,
          pending: 0.0,
          locked: 0.0,
          currency: 'PHP',
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorScheme.primaryColor,
            AppColorScheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ManongWallet',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              manongIcon(size: 40),
            ],
          ),
          const SizedBox(height: 16),

          // Balance
          PriceTag(
            price: w.balance,
            textStyle: const TextStyle(fontSize: 24, color: Colors.white),
          ),
          const SizedBox(height: 8),

          // Pending and Locked
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending: ${w.pending.toStringAsFixed(2)} ${w.currency}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Locked: ${w.locked.toStringAsFixed(2)} ${w.currency}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
