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

enum BookingReadinessStatus { empty, low, ready }

extension BookingReadinessStatusExtension on BookingReadinessStatus {
  String get value => toString().split('.').last;

  int get indexValue => index;
}

class BookingReadiness {
  final double balance;
  final double minimumRequired;
  final int progressPercent;
  final double shortfall;
  final BookingReadinessStatus status;
  final String message;

  BookingReadiness({
    required this.balance,
    required this.minimumRequired,
    required this.progressPercent,
    required this.shortfall,
    required this.status,
    required this.message,
  });

  factory BookingReadiness.fromJson(Map<String, dynamic> json) {
    return BookingReadiness(
      balance: json['balance'] != null
          ? double.tryParse(json['balance'].toString()) ?? 0.0
          : 0.0,
      minimumRequired: json['minimumRequired'] != null
          ? double.tryParse(json['minimumRequired'].toString()) ?? 0.0
          : 0.0,
      progressPercent: json['progressPercent'] != null
          ? int.tryParse(json['progressPercent'].toString()) ?? 0
          : 0,
      shortfall: json['shortfall'] != null
          ? double.tryParse(json['shortfall'].toString()) ?? 0.0
          : 0.0,
      status: BookingReadinessStatus.values.firstWhere(
        (e) => e.value == json['status'].toString(),
        orElse: () => BookingReadinessStatus.empty,
      ),
      message: json['message']?.toString() ?? '',
    );
  }
}
