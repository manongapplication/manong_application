import 'package:manong_application/models/sub_service_item.dart';

class ServiceItem {
  final int id;
  final String title;
  final String description;
  final double priceMin;
  final double priceMax;
  final double ratePerKm;
  final String iconName;
  final String iconColor;
  final bool isActive;
  final DateTime? updatedAt;
  final List<SubServiceItem> subServiceItems;

  ServiceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priceMin,
    required this.priceMax,
    required this.ratePerKm,
    this.iconName = 'handyman',
    this.iconColor = '#3B82F6',
    required this.isActive,
    this.updatedAt,
    this.subServiceItems = const [],
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priceMin: json['priceMin'] != null
          ? double.tryParse(json['priceMin']) ?? 0
          : 0,
      priceMax: json['priceMax'] != null
          ? double.tryParse(json['priceMin']) ?? 0
          : 0,
      ratePerKm: json['ratePerKm'] != null
          ? double.tryParse(json['ratePerKm']) ?? 0
          : 0,
      iconName: json['iconName'] ?? 'handyman',
      iconColor: json['iconColor'] ?? '#3B82F6',
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      subServiceItems:
          (json['subServiceItems'] as List<dynamic>?)
              ?.map((e) => SubServiceItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
