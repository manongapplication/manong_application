import 'package:manong_application/models/user_payment_method.dart';

class AppUser {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String role;
  final bool isVerified;
  final String phone;
  final double? latitude;
  final double? longitude;
  final double? lastKnownLat;
  final double? lastKnownLng;
  final String? fcmToken;
  final String? profilePhoto;
  final List<UserPaymentMethod>? userPaymentMethod;

  AppUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    required this.role,
    required this.isVerified,
    required this.phone,
    this.latitude,
    this.longitude,
    this.lastKnownLat,
    this.lastKnownLng,
    this.fcmToken,
    this.profilePhoto,
    this.userPaymentMethod,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      role: json['role'],
      isVerified: json['isVerified'],
      phone: json['phone'],
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'])
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'])
          : null,
      lastKnownLat: json['lastKnownLat'] != null
          ? double.parse(json['lastKnownLat'])
          : null,
      lastKnownLng: json['lastKnownLng'] != null
          ? double.parse(json['lastKnownLng'])
          : null,
      fcmToken: json['fcmToken'],
      profilePhoto: json['profilePhoto'],
      userPaymentMethod:
          (json['userPaymentMethods'] as List<dynamic>?)
              ?.map((s) => UserPaymentMethod.fromJson(s))
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'AppUser{id: $id, firstName: $firstName, lastName: $lastName, email: $email, role: $role, '
        'isVerified: $isVerified, phone: $phone, latitude: $latitude, '
        'longitude: $longitude, lastKnownLat: $lastKnownLat, '
        'lastKnownLng: $lastKnownLng, profilePhoto: $profilePhoto, '
        'userPaymentMethod: ${userPaymentMethod?.map((e) => e.toString()).toList()}}';
  }
}
