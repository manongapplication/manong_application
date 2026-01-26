class ManongWallet {
  final int id;
  final int manongId;
  final double balance;
  final double pending;
  final double locked;
  final String currency;

  ManongWallet({
    required this.id,
    required this.manongId,
    required this.balance,
    required this.pending,
    required this.locked,
    required this.currency,
  });

  factory ManongWallet.fromJson(Map<String, dynamic> json) {
    return ManongWallet(
      id: json['id'],
      manongId: json['manongId'],
      balance: json['balance'] != null
          ? double.tryParse(json['balance']) ?? 0
          : 0,
      pending: json['pending'] != null
          ? double.tryParse(json['pending']) ?? 0
          : 0,
      locked: json['locked'] != null ? double.tryParse(json['locked']) ?? 0 : 0,
      currency: json['currency'],
    );
  }
}
