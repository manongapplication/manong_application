class UrgencyLevel {
  final int id;
  final String level;
  final String time;
  final double? price;

  const UrgencyLevel({
    required this.id,
    required this.level,
    required this.time,
    this.price,
  });

  factory UrgencyLevel.fromJson(Map<String, dynamic> json) {
    return UrgencyLevel(
      id: json['id'] ?? 0,
      level: json['level'] ?? 'Unknown',
      time: json['time'] ?? 'Not specified',
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'level': level, 'time': time, 'price': price};
  }
}
