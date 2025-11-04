import 'package:manong_application/models/service_item_status.dart';

class SubServiceItem {
  final int id;
  final String title;
  final String iconName;
  final String? description;
  final double? cost;
  final double? fee;
  final double gross;
  final ServiceItemStatus status;

  SubServiceItem({
    required this.id,
    required this.title,
    this.iconName = 'handyman',
    this.description,
    this.cost,
    this.fee,
    required this.gross,
    required this.status,
  });

  factory SubServiceItem.fromJson(Map<String, dynamic> json) {
    return SubServiceItem(
      id: json['id'],
      title: json['title'],
      iconName: json['iconName'],
      description: json['description'],
      cost: json['cost'] != null ? double.tryParse(json['cost']) ?? 0 : 0,
      fee: json['fee'] != null ? double.tryParse(json['fee']) ?? 0 : 0,
      gross: json['gross'] != null ? double.tryParse(json['gross']) ?? 0 : 0,
      status: ServiceItemStatus.values.firstWhere(
        (e) => e.name == json['status'].toString(),
        orElse: () => ServiceItemStatus.inactive,
      ),
    );
  }
}
