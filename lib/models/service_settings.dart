class ServiceSettings {
  final int id;
  final double serviceTax;
  final double maxDistanceFee;

  ServiceSettings({
    required this.id,
    required this.serviceTax,
    required this.maxDistanceFee,
  });

  factory ServiceSettings.fromJson(Map<String, dynamic> json) {
    return ServiceSettings(
      id: json['id'] ?? 0,
      serviceTax: json['serviceTax'] != null
          ? double.tryParse(json['serviceTax'].toString()) ?? 0
          : 0,
      maxDistanceFee: json['maxDistanceFee'] != null
          ? double.tryParse(json['maxDistanceFee'].toString()) ?? 0
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceTax': serviceTax,
      'maxDistanceFee': maxDistanceFee,
    };
  }
}
