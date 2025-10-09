import 'package:manong_application/models/payment_method.dart';

class UserPaymentMethod {
  final int id;
  final int userId;
  final int paymentMethodId;
  final String provider;
  final String? paymentMethodIdOnGateway;
  final String? last4;
  final int? expMonth;
  final int? expYear;
  final String? cardHolderName;
  final String? billingEmail;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PaymentMethod paymentMethod;

  UserPaymentMethod({
    required this.id,
    required this.userId,
    required this.paymentMethod,
    required this.provider,
    this.paymentMethodIdOnGateway,
    this.last4,
    this.expMonth,
    this.expYear,
    this.cardHolderName,
    this.billingEmail,

    this.createdAt,
    this.updatedAt,
    required this.isDefault,
    required this.paymentMethodId,
  });

  factory UserPaymentMethod.fromJson(Map<String, dynamic> json) {
    return UserPaymentMethod(
      id: json['id'],
      userId: json['userId'],
      paymentMethodId: json['paymentMethodId'],
      provider: json['provider'],
      paymentMethodIdOnGateway: json['paymentMethodIdOnGateway'],
      last4: json['last4'],
      expMonth: json['expMonth'],
      expYear: json['expYear'],
      cardHolderName: json['cardHolderName'],
      billingEmail: json['billingEmail'],
      isDefault: json['isDefault'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod']),
    );
  }
}
