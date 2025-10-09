class SubServiceItem {
  final int id;
  final String title;
  final String iconName;
  final String? description;
  final int? cost;
  final int? fee;
  final int gross;
  final bool isActive;

  SubServiceItem({
    required this.id,
    required this.title,
    this.iconName = 'handyman',
    this.description,
    this.cost,
    this.fee,
    required this.gross,
    required this.isActive,
  });

  factory SubServiceItem.fromJson(Map<String, dynamic> json) {
    return SubServiceItem(
      id: json['id'],
      title: json['title'],
      iconName: json['iconName'],
      description: json['description'],
      cost: json['cost'],
      fee: json['fee'],
      gross: json['gross'],
      isActive: json['isActive'],
    );
  }
}
