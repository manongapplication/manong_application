import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/sub_service_item.dart';

class Manong {
  final AppUser appUser;
  final ManongProfile? profile;

  Manong({required this.appUser, this.profile});

  factory Manong.fromJson(Map<String, dynamic> json) {
    return Manong(
      appUser: AppUser.fromJson(json),
      profile:
          json['manongProfile'] != null &&
              (json['manongProfile'] as List).isNotEmpty
          ? ManongProfile.fromJson(json['manongProfile'][0])
          : null,
    );
  }
}

class ManongProfile {
  final int id;
  final int userId;
  final String status;
  final String? licenseNumber;
  final int? yearsExperience;
  final double? hourlyRate;
  final double? startingPrice;
  final bool isProfessionallyVerified;
  final List<ManongSpeciality>? specialities;

  ManongProfile({
    required this.id,
    required this.userId,
    required this.status,
    this.licenseNumber,
    this.yearsExperience,
    this.hourlyRate,
    this.startingPrice,
    required this.isProfessionallyVerified,
    this.specialities = const [],
  });

  factory ManongProfile.fromJson(Map<String, dynamic> json) {
    return ManongProfile(
      id: json['id'],
      userId: json['userId'],
      status: json['status'] ?? 'unknown',
      licenseNumber: json['licenseNumber'],
      yearsExperience: json['yearsExperience'] != null
          ? int.tryParse(json['yearsExperience'].toString())
          : null,
      hourlyRate: json['hourlyRate'] != null
          ? double.tryParse(json['hourlyRate'].toString())
          : null,
      startingPrice: json['startingPrice'] != null
          ? double.tryParse(json['startingPrice'].toString())
          : null,
      isProfessionallyVerified: json['isProfessionallyVerified'] ?? false,
      specialities:
          (json['manongSpecialities'] as List<dynamic>?)
              ?.map((s) => ManongSpeciality.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class ManongSpeciality {
  final int id;
  final int subServiceItemId;
  final SubServiceItem subServiceItem;

  ManongSpeciality({
    required this.id,
    required this.subServiceItemId,
    required this.subServiceItem,
  });

  factory ManongSpeciality.fromJson(Map<String, dynamic> json) {
    return ManongSpeciality(
      id: json['id'],
      subServiceItemId: json['subServiceItemId'],
      subServiceItem: SubServiceItem.fromJson(json['subServiceItem']),
    );
  }
}
