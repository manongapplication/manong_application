import 'package:flutter/widgets.dart';
import 'package:manong_application/models/account_status.dart';
import 'package:manong_application/models/address_category.dart';
import 'package:manong_application/models/service_request.dart';
import 'package:manong_application/models/user_feedback.dart';
import 'package:manong_application/models/user_payment_method.dart';
import 'package:manong_application/models/user_role.dart';

class AppUser {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? nickname;
  final String? email;
  final UserRole role;
  final bool isVerified;
  final String phone;
  final AddressCategory? addressCategory;
  final String? addressLine;
  final double? latitude;
  final double? longitude;
  final double? lastKnownLat;
  final double? lastKnownLng;
  final String? fcmToken;
  final String? profilePhoto;
  final AccountStatus status;
  final bool hasSeenVerificationCongrats;
  final List<UserPaymentMethod>? userPaymentMethod;

  final List<UserFeedback>? givenFeedbacks;
  final List<UserFeedback>? receivedFeedbacks;

  final List<ServiceRequest>? userRequests;

  AppUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.nickname,
    this.email,
    required this.role,
    required this.isVerified,
    required this.phone,
    this.addressCategory,
    this.addressLine,
    this.latitude,
    this.longitude,
    this.lastKnownLat,
    this.lastKnownLng,
    this.fcmToken,
    this.profilePhoto,
    required this.status,
    required this.hasSeenVerificationCongrats,
    this.userPaymentMethod,

    this.givenFeedbacks,
    this.receivedFeedbacks,
    this.userRequests,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      nickname: json['nickname'],
      email: json['email'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'].toString(),
        orElse: () => UserRole.customer,
      ),
      isVerified: json['isVerified'],
      phone: json['phone'],
      addressCategory: json['addressCategory'] != null
          ? AddressCategory.values.firstWhere(
              (e) => e.name == json['addressCategory'].toString(),
              orElse: () => AddressCategory.residential,
            )
          : null,
      addressLine: json['addressLine'],
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
      status: AccountStatus.values.firstWhere(
        (e) => e.value == json['status'].toString(),
        orElse: () => AccountStatus.pending,
      ),
      hasSeenVerificationCongrats: json['hasSeenVerificationCongrats'],
      userPaymentMethod:
          (json['userPaymentMethods'] as List<dynamic>?)
              ?.map((s) => UserPaymentMethod.fromJson(s))
              .toList() ??
          [],

      givenFeedbacks:
          (json['givenFeedbacks'] as List<dynamic>?)
              ?.map((e) => UserFeedback.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      receivedFeedbacks:
          (json['receivedFeedbacks'] as List<dynamic>?)
              ?.map((e) => UserFeedback.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],

      userRequests:
          (json['userRequests'] as List<dynamic>?)
              ?.map((e) => ServiceRequest.fromJson(e as Map<String, dynamic>))
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
        'userPaymentMethod: ${userPaymentMethod?.map((e) => e.toString()).toList()}, '
        'givenFeedbacks: ${givenFeedbacks?.map((e) => e.toString()).toList()}, '
        'receivedFeedbacks: ${receivedFeedbacks?.map((e) => e.toString()).toList()}}';
  }
}
