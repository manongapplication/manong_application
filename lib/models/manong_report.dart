import 'dart:io';

import 'package:manong_application/models/manong.dart';
import 'package:manong_application/models/service_request.dart';

class ManongReport {
  final int id;
  final int serviceRequestId;
  final int manongId;
  final String summary;
  final String? details;
  final String? materialsUsed;
  final int? laborDuration;
  late final List<File>? images;
  final String? issuesFound;
  final bool? customerPresent;
  final bool? verifiedByUser;
  final double? totalCost;
  final String? warrantyInfo;
  final String? recommendations;

  final ServiceRequest? serviceRequest;
  final Manong? manong;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  ManongReport({
    required this.id,
    required this.serviceRequestId,
    required this.manongId,
    required this.summary,
    this.details,
    this.materialsUsed,
    this.laborDuration,
    this.images,
    this.issuesFound,
    this.customerPresent,
    this.verifiedByUser,
    this.totalCost,
    this.warrantyInfo,
    this.recommendations,
    this.serviceRequest,
    this.manong,
    this.createdAt,
    this.updatedAt,
  });

  ManongReport copyWith({
    int? id,
    int? serviceRequestId,
    int? manongId,
    String? summary,
    String? details,
    String? materialsUsed,
    int? laborDuration,
    List<File>? images,
    String? issuesFound,
    bool? customerPresent,
    bool? verifiedByUser,
    double? totalCost,
    String? warrantyInfo,
    String? recommendations,
    ServiceRequest? serviceRequest,
    Manong? manong,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ManongReport(
      id: id ?? this.id,
      serviceRequestId: serviceRequestId ?? this.serviceRequestId,
      manongId: manongId ?? this.manongId,
      summary: summary ?? this.summary,
      details: details ?? this.details,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      laborDuration: laborDuration ?? this.laborDuration,
      images: images ?? this.images,
      issuesFound: issuesFound ?? this.issuesFound,
      customerPresent: customerPresent ?? this.customerPresent,
      verifiedByUser: verifiedByUser ?? this.verifiedByUser,
      totalCost: totalCost ?? this.totalCost,
      warrantyInfo: warrantyInfo ?? this.warrantyInfo,
      recommendations: recommendations ?? this.recommendations,
      serviceRequest: serviceRequest ?? this.serviceRequest,
      manong: manong ?? this.manong,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ManongReport.fromJson(Map<String, dynamic> json) {
    return ManongReport(
      id: json['id'],
      serviceRequestId: json['serviceRequestId'],
      manongId: json['manongId'],
      summary: json['summary'],
      details: json['details'],
      materialsUsed: json['materialsUsed'],
      laborDuration: json['laborDuration'] != null
          ? int.tryParse(json['laborDuration'].toString())
          : null,
      images: json['imagesPath'] == null
          ? []
          : (json['imagesPath'] is List
                ? (json['imagesPath'] as List)
                      .map((path) => File(path.toString()))
                      .toList()
                : [File(json['imagesPath'].toString())]),
      issuesFound: json['issuesFound'],
      customerPresent: json['customerPresent'],
      verifiedByUser: json['verifiedByUser'],
      totalCost: json['totalCost'] != null
          ? double.tryParse(json['totalCost'].toString())
          : null,
      warrantyInfo: json['warrantyInfo'],
      recommendations: json['recommendations'],
      serviceRequest: json['serviceRequest'] != null
          ? ServiceRequest.fromJson(json['serviceRequest'])
          : null,
      manong: json['manong'] != null ? Manong.fromJson(json['manong']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceRequestId': serviceRequestId,
      'manongId': manongId,
      'summary': summary,
      'details': details,
      'materialsUsed': materialsUsed,
      'laborDuration': laborDuration,
      'imagesPath': images?.map((file) => file.path).toList(),
      'issuesFound': issuesFound,
      'customerPresent': customerPresent,
      'verifiedByUser': verifiedByUser,
      'totalCost': totalCost,
      'warrantyInfo': warrantyInfo,
      'recommendations': recommendations,
      'serviceRequest': serviceRequest?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ManongReport('
        'id: $id, '
        'serviceRequestId: $serviceRequestId, '
        'manongId: $manongId, '
        'summary: $summary, '
        'details: $details, '
        'materialsUsed: $materialsUsed, '
        'laborDuration: $laborDuration, '
        'images: ${images?.map((f) => f.path).toList()}, '
        'issuesFound: $issuesFound, '
        'customerPresent: $customerPresent, '
        'verifiedByUser: $verifiedByUser, '
        'totalCost: $totalCost, '
        'warrantyInfo: $warrantyInfo, '
        'recommendations: $recommendations, '
        'serviceRequest: ${serviceRequest?.toString()}, '
        'manong: ${manong?.toString()}, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
