class PaymentMethod {
  int id;
  String name;
  String code;
  bool isActive;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code, 'is_active': isActive};
  }

  @override
  String toString() {
    return 'PaymentMethod(id: $id, name: $name, code: $code, isActive: $isActive)';
  }
}
