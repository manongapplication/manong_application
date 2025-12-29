import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/manong_status.dart';
import 'package:manong_application/models/sub_service_item.dart';

class Manong {
  final AppUser appUser;
  final ManongProfile? profile;

  Manong({required this.appUser, this.profile});

  factory Manong.fromJson(Map<String, dynamic> json) {
    return Manong(
      appUser: AppUser.fromJson(json),
      profile: json['manongProfile'] != null
          ? ManongProfile.fromJson(json['manongProfile'])
          : null,
    );
  }
}

class ManongProfile {
  final int id;
  final int userId;
  final ManongStatus status;
  final String? licenseNumber;
  final int? yearsExperience;
  final double? hourlyRate;
  final double? startingPrice;
  final bool isProfessionallyVerified;
  final int dailyServiceLimit;
  final String? experienceDescription;
  final List<ManongSpeciality>? specialities;
  final List<ManongAssistant>? manongAssistants;

  ManongProfile({
    required this.id,
    required this.userId,
    required this.status,
    this.licenseNumber,
    this.yearsExperience,
    this.hourlyRate,
    this.startingPrice,
    required this.isProfessionallyVerified,
    required this.dailyServiceLimit,
    this.experienceDescription,
    this.specialities = const [],
    this.manongAssistants,
  });

  factory ManongProfile.fromJson(Map<String, dynamic> json) {
    return ManongProfile(
      id: json['id'],
      userId: json['userId'],
      status: ManongStatus.values.firstWhere(
        (e) => e.name == json['status'].toString(),
        orElse: () => ManongStatus.inactive,
      ),
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
      dailyServiceLimit: json['dailyServiceLimit'] ?? 5,
      experienceDescription: json['experienceDescription'],
      specialities:
          (json['manongSpecialities'] as List<dynamic>?)
              ?.map((s) => ManongSpeciality.fromJson(s))
              .toList() ??
          [],
      manongAssistants:
          (json['manongAssistants'] as List<dynamic>?)
              ?.map((a) => ManongAssistant.fromJson(a))
              .toList() ??
          [],
    );
  }

  ManongProfile copyWith({
    int? id,
    int? userId,
    ManongStatus? status,
    String? licenseNumber,
    int? yearsExperience,
    double? hourlyRate,
    double? startingPrice,
    bool? isProfessionallyVerified,
    int? dailyServiceLimit,
    String? experienceDescription,
    List<ManongSpeciality>? specialities,
    List<ManongAssistant>? manongAssistants,
  }) {
    return ManongProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      startingPrice: startingPrice ?? this.startingPrice,
      isProfessionallyVerified:
          isProfessionallyVerified ?? this.isProfessionallyVerified,
      dailyServiceLimit: dailyServiceLimit ?? this.dailyServiceLimit,
      experienceDescription:
          experienceDescription ?? this.experienceDescription,
      specialities: specialities ?? this.specialities,
      manongAssistants: manongAssistants ?? this.manongAssistants,
    );
  }
}

class ManongAssistant {
  final int id;
  final int manongProfileId;
  final String fullName;
  final String? phone;

  ManongAssistant({
    required this.id,
    required this.manongProfileId,
    required this.fullName,
    this.phone,
  });

  factory ManongAssistant.fromJson(Map<String, dynamic> json) {
    return ManongAssistant(
      id: json['id'],
      manongProfileId: json['manongProfileId'],
      fullName: json['fullName'],
      phone: json['phone'],
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

class ManongDailyLimit {
  final bool isReached;
  final String? message;
  final int? count;
  final int? limit;

  ManongDailyLimit({
    required this.isReached,
    this.message,
    this.count,
    this.limit,
  });
}
