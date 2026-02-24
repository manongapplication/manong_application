import 'package:flutter/material.dart';

class BanksUtils {
  final List<Map<String, dynamic>> banks = [
    // Digital Wallets
    {
      'id': 'gcash',
      'name': 'GCash',
      'code': 'GCASH',
      'icon': Icons.phone_android,
      'color': const Color(0xFF0066B3),
      'type': 'digital_wallet',
    },
    {
      'id': 'maya',
      'name': 'Maya',
      'code': 'MAYA',
      'icon': Icons.credit_card,
      'color': const Color(0xFF00B5B0),
      'type': 'digital_wallet',
    },

    // Traditional Banks
    {
      'id': 'bpi',
      'name': 'BPI',
      'code': 'BPI',
      'icon': Icons.account_balance,
      'color': const Color(0xFFE1261C),
      'type': 'bank',
    },
    {
      'id': 'bdo',
      'name': 'BDO',
      'code': 'BDO',
      'icon': Icons.account_balance,
      'color': const Color(0xFFE1261C),
      'type': 'bank',
    },
    {
      'id': 'metrobank',
      'name': 'Metrobank',
      'code': 'MBTC',
      'icon': Icons.account_balance,
      'color': const Color(0xFF0055A6),
      'type': 'bank',
    },
    {
      'id': 'landbank',
      'name': 'Landbank',
      'code': 'LBP',
      'icon': Icons.account_balance,
      'color': const Color(0xFF006747),
      'type': 'bank',
    },
    {
      'id': 'unionbank',
      'name': 'UnionBank',
      'code': 'UBP',
      'icon': Icons.account_balance,
      'color': const Color(0xFF0066B3),
      'type': 'bank',
    },
    {
      'id': 'security_bank',
      'name': 'Security Bank',
      'code': 'SBC',
      'icon': Icons.account_balance,
      'color': const Color(0xFFFFCC00),
      'type': 'bank',
    },
    {
      'id': 'rcbc',
      'name': 'RCBC',
      'code': 'RCBC',
      'icon': Icons.account_balance,
      'color': const Color(0xFF004B87),
      'type': 'bank',
    },
    {
      'id': 'chinabank',
      'name': 'China Bank',
      'code': 'CBC',
      'icon': Icons.account_balance,
      'color': const Color(0xFFCE1126),
      'type': 'bank',
    },
    {
      'id': 'pnb',
      'name': 'PNB',
      'code': 'PNB',
      'icon': Icons.account_balance,
      'color': const Color(0xFF6A0DAD),
      'type': 'bank',
    },
  ];
}
