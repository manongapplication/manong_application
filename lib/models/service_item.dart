import 'package:manong_application/models/sub_service_item.dart';

class ServiceItem {
  final int id;
  final String title;
  final String description;
  final int priceMin;
  final int priceMax;
  final String iconName;
  final String iconColor;
  final bool isActive;
  final List<SubServiceItem> subServiceItems;

  ServiceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priceMin,
    required this.priceMax,
    this.iconName = 'handyman',
    this.iconColor = '#3B82F6',
    required this.isActive,
    this.subServiceItems = const [],
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priceMin: json['priceMin'] ?? 0,
      priceMax: json['priceMax'] ?? 0,
      iconName: json['iconName'] ?? 'handyman',
      iconColor: json['iconColor'] ?? '#3B82F6',
      isActive: json['isActive'] == 1 || json['isActive'] == true,
      subServiceItems:
          (json['subServiceItems'] as List<dynamic>?)
              ?.map((e) => SubServiceItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
