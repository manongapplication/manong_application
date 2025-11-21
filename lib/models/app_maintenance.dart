class AppMaintenance {
  final int id;
  final bool isActive;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? message;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppMaintenance({
    required this.id,
    required this.isActive,
    this.startTime,
    this.endTime,
    this.message,
    this.createdAt,
    this.updatedAt,
  });

  factory AppMaintenance.fromJson(Map<String, dynamic> json) {
    return AppMaintenance(
      id: json['id'],
      isActive: json['isActive'],
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'])
          : null,
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'])
          : null,
      message: json['message'],

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}
